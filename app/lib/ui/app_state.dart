import 'package:flutter/material.dart';
import 'package:epo_app/data/ble_service.dart';
import 'package:epo_app/repository/medication_repository.dart';
import 'package:epo_app/data/models/medication.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class AppState extends ChangeNotifier {
  final BLEService bleService;
  final MedicationRepository medicationRepository;

  BluetoothConnectionState connectionState = BluetoothConnectionState.disconnected;
  List<Medication> medications = [];
  StreamSubscription? _medsSubscription;

  AppState(this.bleService, this.medicationRepository) {
    bleService.connectionState.listen((state) {
      connectionState = state;
      notifyListeners();
    });

    bleService.notifications.listen((message) {
      if (message.startsWith("INTAKE_CONFIRMED") || message.startsWith("ALARM_START")) {
        String? medId;

        if (medications.isNotEmpty) {
          // Parse slot index if available, e.g. "INTAKE_CONFIRMED:1"
          int slotIndex = 0; // Default to the first slot for the prototype

          if (message.contains(":")) {
            final parts = message.split(":");
            if (parts.length > 1) {
              final parsedIndex = int.tryParse(parts[1]);
              if (parsedIndex != null && parsedIndex >= 0 && parsedIndex < medications.length) {
                slotIndex = parsedIndex;
              }
            }
          }

          medId = medications[slotIndex].id;
        }

        // Use the base event name without the slot suffix for logging
        String baseEvent = message.contains(":") ? message.split(":")[0] : message;
        medicationRepository.logIntake(baseEvent, medicationId: medId);
      }
    });

    _medsSubscription = medicationRepository.getMedications().listen((meds) {
      // Pre-sort medications by their earliest dose for performance
      final sortedMeds = List<Medication>.from(meds);
      sortedMeds.sort((a, b) {
        int aTime = (a.scheduleHours.first * 60) + a.scheduleMinutes.first;
        int bTime = (b.scheduleHours.first * 60) + b.scheduleMinutes.first;
        return aTime.compareTo(bTime);
      });
      medications = sortedMeds;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _medsSubscription?.cancel();
    super.dispose();
  }
}

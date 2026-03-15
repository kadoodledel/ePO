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
  bool alarmActive = false;
  StreamSubscription? _medsSubscription;

  AppState(this.bleService, this.medicationRepository) {
    bleService.connectionState.listen((state) {
      connectionState = state;
      notifyListeners();
    });

    bleService.notifications.listen((message) {
      if (message == "ALARM_START") {
        // Alarm has started — notify the UI, but do not log an intake yet.
        alarmActive = true;
        notifyListeners();
      } else if (message == "INTAKE_CONFIRMED") {
        // TODO: Implement multi-slot support.
        // For the prototype, we assume the first medication is the one being tracked.
        // In a real scenario, we'd have a way to identify which med is in which slot.
        alarmActive = false;
        String? medId = medications.isNotEmpty ? medications.first.id : null;
        medicationRepository.logIntake(message, medicationId: medId);
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

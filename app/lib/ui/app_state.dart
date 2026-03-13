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
      if (message == "INTAKE_CONFIRMED" || message == "ALARM_START") {
        // TODO: Implement multi-slot support.
        // For the prototype, we assume the first medication is the one being tracked.
        // In a real scenario, we'd have a way to identify which med is in which slot.
        String? medId = medications.isNotEmpty ? medications.first.id : null;
        medicationRepository.logIntake(message, medicationId: medId);
      }
    });

    _medsSubscription = medicationRepository.getMedications().listen((meds) {
      medications = meds;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _medsSubscription?.cancel();
    super.dispose();
  }
}

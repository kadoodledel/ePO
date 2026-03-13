import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epo_app/data/ble_service.dart';
import 'package:epo_app/repository/medication_repository.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class AppState extends ChangeNotifier {
  final BLEService bleService;
  final MedicationRepository medicationRepository;

  BluetoothConnectionState connectionState = BluetoothConnectionState.disconnected;

  AppState(this.bleService, this.medicationRepository) {
    bleService.connectionState.listen((state) {
      connectionState = state;
      notifyListeners();
    });

    bleService.notifications.listen((message) {
      if (message == "INTAKE_CONFIRMED" || message == "ALARM_START") {
        medicationRepository.logIntake(message);
      }
    });
  }
}

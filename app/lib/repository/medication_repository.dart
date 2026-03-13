import 'dart:async';
import 'package:epo_app/data/models/medication.dart';

class MedicationRepository {
  // In-memory storage for prototype
  final List<Medication> _medications = [];
  final StreamController<List<Medication>> _medsController = StreamController<List<Medication>>.broadcast();

  // Local settings storage
  final Map<String, dynamic> _settings = {};
  final StreamController<Map<String, dynamic>> _settingsController = StreamController<Map<String, dynamic>>.broadcast();

  MedicationRepository() {
    // Seed with a sample medication for testing if empty
    _medications.add(Medication(
      id: '1',
      name: 'Example Med',
      dosage: '10mg',
      stockCount: 10,
      scheduleHours: [8],
      scheduleMinutes: [0],
    ));
    _medsController.add(List.unmodifiable(_medications));
  }

  Future<void> logIntake(String event, {String? medicationId}) async {
    print("Logging intake event: $event for medication: $medicationId");

    if (event == "INTAKE_CONFIRMED" && medicationId != null) {
      int index = _medications.indexWhere((m) => m.id == medicationId);
      if (index != -1) {
        _medications[index] = _medications[index].copyWith(
          stockCount: _medications[index].stockCount - 1,
        );
        _medsController.add(List.unmodifiable(_medications));
      }
    }
  }

  Future<void> addMedication(Medication medication) async {
    final newMed = medication.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    _medications.add(newMed);
    _medsController.add(List.unmodifiable(_medications));
  }

  Future<void> updateMedication(Medication medication) async {
    int index = _medications.indexWhere((m) => m.id == medication.id);
    if (index != -1) {
      _medications[index] = medication;
      _medsController.add(List.unmodifiable(_medications));
    }
  }

  Stream<List<Medication>> getMedications() {
    // Return a stream that emits current state then future updates
    Timer.run(() => _medsController.add(List.unmodifiable(_medications)));
    return _medsController.stream;
  }

  Future<void> updateSettings({int? alarmHour, int? alarmMinute, int? duration, int? interval}) async {
    if (alarmHour != null) _settings['alarmHour'] = alarmHour;
    if (alarmMinute != null) _settings['alarmMinute'] = alarmMinute;
    if (duration != null) _settings['duration'] = duration;
    if (interval != null) _settings['interval'] = interval;

    if (_settings.isNotEmpty) {
      _settingsController.add(Map.unmodifiable(_settings));
    }
  }

  Stream<Map<String, dynamic>> getSettings() {
    Timer.run(() => _settingsController.add(Map.unmodifiable(_settings)));
    return _settingsController.stream;
  }
}

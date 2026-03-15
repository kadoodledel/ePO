import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epo_app/data/models/medication.dart';

class MedicationRepository {
  static const String _medsKey = 'medications';

  late SharedPreferences _prefs;
  final List<Medication> _medications = [];
  final StreamController<List<Medication>> _medsController = StreamController<List<Medication>>.broadcast();

  // Local settings storage
  final Map<String, dynamic> _settings = {};
  final StreamController<Map<String, dynamic>> _settingsController = StreamController<Map<String, dynamic>>.broadcast();

  /// Must be called once before using the repository.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final raw = _prefs.getString(_medsKey);
    _medications.clear();
    if (raw != null) {
      final List<dynamic> decoded = jsonDecode(raw);
      for (final entry in decoded) {
        final map = Map<String, dynamic>.from(entry);
        final id = map['id'] as String;
        _medications.add(Medication.fromMap(id, map));
      }
    } else {
      // First launch — seed with example medication
      _medications.add(Medication(
        id: '1',
        name: 'Example Med',
        dosage: '10mg',
        stockCount: 10,
        scheduleHours: [8],
        scheduleMinutes: [0],
      ));
      _saveToPrefs();
    }
    _medsController.add(List.unmodifiable(_medications));
  }

  void _saveToPrefs() {
    final List<Map<String, dynamic>> data = _medications.map((m) {
      final map = m.toMap();
      map['id'] = m.id;
      return map;
    }).toList();
    _prefs.setString(_medsKey, jsonEncode(data));
  }

  Future<void> logIntake(String event, {String? medicationId}) async {
    print("Logging intake event: $event for medication: $medicationId");

    if (event == "INTAKE_CONFIRMED" && medicationId != null) {
      int index = _medications.indexWhere((m) => m.id == medicationId);
      if (index != -1) {
        _medications[index] = _medications[index].copyWith(
          stockCount: _medications[index].stockCount - 1,
        );
        _saveToPrefs();
        _medsController.add(List.unmodifiable(_medications));
      }
    }
  }

  Future<void> addMedication(Medication medication) async {
    final newMed = medication.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    _medications.add(newMed);
    _saveToPrefs();
    _medsController.add(List.unmodifiable(_medications));
  }

  Future<void> updateMedication(Medication medication) async {
    int index = _medications.indexWhere((m) => m.id == medication.id);
    if (index != -1) {
      _medications[index] = medication;
      _saveToPrefs();
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

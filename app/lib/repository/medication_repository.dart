import 'dart:async';
import 'dart:convert';
import 'package:epo_app/data/models/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicationRepository {
  static const _medsKey = 'medications';
  static const _settingsKey = 'settings';

  final List<Medication> _medications = [];
  final StreamController<List<Medication>> _medsController =
      StreamController<List<Medication>>.broadcast();

  final Map<String, dynamic> _settings = {};
  final StreamController<Map<String, dynamic>> _settingsController =
      StreamController<Map<String, dynamic>>.broadcast();

  MedicationRepository();

  Future<void> initialize() => _loadFromDisk();

  // ---------------------------------------------------------------------------
  // Persistence helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();

    final medsJson = prefs.getString(_medsKey);
    if (medsJson != null) {
      final List<dynamic> decoded = jsonDecode(medsJson) as List<dynamic>;
      _medications.addAll(
        decoded.map((e) => Medication.fromMap(e as Map<String, dynamic>)),
      );
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
      await _saveMeds(prefs);
    }

    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson != null) {
      _settings.addAll(
        Map<String, dynamic>.from(jsonDecode(settingsJson) as Map),
      );
    }

    _medsController.add(List.unmodifiable(_medications));
    if (_settings.isNotEmpty) {
      _settingsController.add(Map.unmodifiable(_settings));
    }
  }

  Future<void> _saveMeds([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setString(
      _medsKey,
      jsonEncode(_medications.map((m) => m.toMap()).toList()),
    );
  }

  Future<void> _saveSettings([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    await p.setString(_settingsKey, jsonEncode(_settings));
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> logIntake(String event, {String? medicationId}) async {
    if (event == 'INTAKE_CONFIRMED' && medicationId != null) {
      final index = _medications.indexWhere((m) => m.id == medicationId);
      if (index != -1) {
        _medications[index] = _medications[index].copyWith(
          stockCount: _medications[index].stockCount - 1,
        );
        _medsController.add(List.unmodifiable(_medications));
        await _saveMeds();
      }
    }
  }

  Future<void> addMedication(Medication medication) async {
    final newMed = medication.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _medications.add(newMed);
    _medsController.add(List.unmodifiable(_medications));
    await _saveMeds();
  }

  Future<void> updateMedication(Medication medication) async {
    final index = _medications.indexWhere((m) => m.id == medication.id);
    if (index != -1) {
      _medications[index] = medication;
      _medsController.add(List.unmodifiable(_medications));
      await _saveMeds();
    }
  }

  Stream<List<Medication>> getMedications() {
    Timer.run(() => _medsController.add(List.unmodifiable(_medications)));
    return _medsController.stream;
  }

  Future<void> updateSettings({
    int? alarmHour,
    int? alarmMinute,
    int? duration,
    int? interval,
  }) async {
    if (alarmHour != null) _settings['alarmHour'] = alarmHour;
    if (alarmMinute != null) _settings['alarmMinute'] = alarmMinute;
    if (duration != null) _settings['duration'] = duration;
    if (interval != null) _settings['interval'] = interval;

    if (_settings.isNotEmpty) {
      _settingsController.add(Map.unmodifiable(_settings));
      await _saveSettings();
    }
  }

  Stream<Map<String, dynamic>> getSettings() {
    Timer.run(() => _settingsController.add(Map.unmodifiable(_settings)));
    return _settingsController.stream;
  }
}

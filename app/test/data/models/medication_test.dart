import 'package:flutter_test/flutter_test.dart';
import 'package:epo_app/data/models/medication.dart';

void main() {
  group('Medication Model Tests', () {
    final tMedication = Medication(
      id: 'med-123',
      name: 'Amoxicillin',
      dosage: '500mg',
      stockCount: 30,
      scheduleHours: [8, 20],
      scheduleMinutes: [0, 30],
    );

    test('toMap should return a valid map representation', () {
      final result = tMedication.toMap();

      final expectedMap = {
        'name': 'Amoxicillin',
        'dosage': '500mg',
        'stockCount': 30,
        'scheduleHours': [8, 20],
        'scheduleMinutes': [0, 30],
      };

      expect(result, expectedMap);
    });

    test('fromMap should return a valid Medication object', () {
      final map = {
        'name': 'Amoxicillin',
        'dosage': '500mg',
        'stockCount': 30,
        'scheduleHours': [8, 20],
        'scheduleMinutes': [0, 30],
      };

      final result = Medication.fromMap('med-123', map);

      expect(result.id, 'med-123');
      expect(result.name, 'Amoxicillin');
      expect(result.dosage, '500mg');
      expect(result.stockCount, 30);
      expect(result.scheduleHours, [8, 20]);
      expect(result.scheduleMinutes, [0, 30]);
    });

    test('fromMap should handle missing or null fields gracefully', () {
      final map = <String, dynamic>{};

      final result = Medication.fromMap('med-456', map);

      expect(result.id, 'med-456');
      expect(result.name, '');
      expect(result.dosage, '');
      expect(result.stockCount, 0);
      expect(result.scheduleHours, []);
      expect(result.scheduleMinutes, []);
    });

    test('fromMap should handle null lists gracefully', () {
      final map = <String, dynamic>{
        'scheduleHours': null,
        'scheduleMinutes': null,
      };

      final result = Medication.fromMap('med-456', map);

      expect(result.scheduleHours, []);
      expect(result.scheduleMinutes, []);
    });

    test('copyWith should return a new object with updated properties', () {
      final result = tMedication.copyWith(
        name: 'Ibuprofen',
        stockCount: 15,
      );

      expect(result.id, 'med-123'); // Unchanged
      expect(result.name, 'Ibuprofen'); // Changed
      expect(result.dosage, '500mg'); // Unchanged
      expect(result.stockCount, 15); // Changed
      expect(result.scheduleHours, [8, 20]); // Unchanged
      expect(result.scheduleMinutes, [0, 30]); // Unchanged
    });
  });
}

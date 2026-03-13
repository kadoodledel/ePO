import 'package:flutter_test/flutter_test.dart';
import 'package:epo_app/data/models/medication.dart';

void main() {
  group('Medication.copyWith', () {
    late Medication originalMedication;

    setUp(() {
      originalMedication = Medication(
        id: '1',
        name: 'Aspirin',
        dosage: '100mg',
        stockCount: 30,
        scheduleHours: [8, 20],
        scheduleMinutes: [0, 30],
      );
    });

    test('should return a new object with the same values when no arguments are provided', () {
      final copy = originalMedication.copyWith();

      expect(copy.id, originalMedication.id);
      expect(copy.name, originalMedication.name);
      expect(copy.dosage, originalMedication.dosage);
      expect(copy.stockCount, originalMedication.stockCount);
      expect(copy.scheduleHours, originalMedication.scheduleHours);
      expect(copy.scheduleMinutes, originalMedication.scheduleMinutes);
      // It should be a different instance if possible, though copyWith usually returns a new instance
      expect(identical(copy, originalMedication), isFalse);
    });

    test('should return a new object with updated values when specific arguments are provided', () {
      final copy = originalMedication.copyWith(
        name: 'Ibuprofen',
        stockCount: 50,
      );

      expect(copy.id, originalMedication.id);
      expect(copy.name, 'Ibuprofen');
      expect(copy.dosage, originalMedication.dosage);
      expect(copy.stockCount, 50);
      expect(copy.scheduleHours, originalMedication.scheduleHours);
      expect(copy.scheduleMinutes, originalMedication.scheduleMinutes);
    });

    test('should return a new object with all values updated when all arguments are provided', () {
      final copy = originalMedication.copyWith(
        id: '2',
        name: 'Tylenol',
        dosage: '500mg',
        stockCount: 100,
        scheduleHours: [9],
        scheduleMinutes: [15],
      );

      expect(copy.id, '2');
      expect(copy.name, 'Tylenol');
      expect(copy.dosage, '500mg');
      expect(copy.stockCount, 100);
      expect(copy.scheduleHours, [9]);
      expect(copy.scheduleMinutes, [15]);
    });
  });
}

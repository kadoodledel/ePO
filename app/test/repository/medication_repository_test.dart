import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epo_app/repository/medication_repository.dart';

void main() {
  group('MedicationRepository.logIntake', () {
    late MedicationRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repository = MedicationRepository();
      await repository.initialize();
    });

    test('should decrement stockCount when event is INTAKE_CONFIRMED and valid medicationId is provided', () async {
      // Setup
      final medsStream = repository.getMedications();
      final initialMeds = await medsStream.first;
      final initialMed = initialMeds.firstWhere((m) => m.id == '1');
      final initialStock = initialMed.stockCount;

      // Execute
      await repository.logIntake('INTAKE_CONFIRMED', medicationId: '1');

      // Verify
      final updatedMeds = await repository.getMedications().first;
      final updatedMed = updatedMeds.firstWhere((m) => m.id == '1');

      expect(updatedMed.stockCount, equals(initialStock - 1));
    });

    test('should not decrement stockCount when event is not INTAKE_CONFIRMED', () async {
      // Setup
      final medsStream = repository.getMedications();
      final initialMeds = await medsStream.first;
      final initialMed = initialMeds.firstWhere((m) => m.id == '1');
      final initialStock = initialMed.stockCount;

      // Execute
      await repository.logIntake('OTHER_EVENT', medicationId: '1');

      // Verify
      final updatedMeds = await repository.getMedications().first;
      final updatedMed = updatedMeds.firstWhere((m) => m.id == '1');

      expect(updatedMed.stockCount, equals(initialStock));
    });

    test('should not decrement stockCount when medicationId is null', () async {
      // Setup
      final medsStream = repository.getMedications();
      final initialMeds = await medsStream.first;
      final initialMed = initialMeds.firstWhere((m) => m.id == '1');
      final initialStock = initialMed.stockCount;

      // Execute
      await repository.logIntake('INTAKE_CONFIRMED', medicationId: null);

      // Verify
      final updatedMeds = await repository.getMedications().first;
      final updatedMed = updatedMeds.firstWhere((m) => m.id == '1');

      expect(updatedMed.stockCount, equals(initialStock));
    });

    test('should not decrement stockCount when medicationId is not found', () async {
      // Setup
      final medsStream = repository.getMedications();
      final initialMeds = await medsStream.first;
      final initialMed = initialMeds.firstWhere((m) => m.id == '1');
      final initialStock = initialMed.stockCount;

      // Execute
      await repository.logIntake('INTAKE_CONFIRMED', medicationId: '999');

      // Verify
      final updatedMeds = await repository.getMedications().first;
      final updatedMed = updatedMeds.firstWhere((m) => m.id == '1');

      expect(updatedMed.stockCount, equals(initialStock));
    });

    test('should seed example medication on first launch (empty storage)', () async {
      final meds = await repository.getMedications().first;
      expect(meds.length, equals(1));
      expect(meds.first.id, equals('1'));
      expect(meds.first.name, equals('Example Med'));
    });

    test('should persist medications across reinitialisation', () async {
      // Decrement stock so we have something changed to persist
      await repository.logIntake('INTAKE_CONFIRMED', medicationId: '1');

      // Create a new repository backed by the same SharedPreferences instance
      final repository2 = MedicationRepository();
      await repository2.initialize();

      final meds = await repository2.getMedications().first;
      final med = meds.firstWhere((m) => m.id == '1');
      // Stock should be 9 (decremented from 10) after reload
      expect(med.stockCount, equals(9));
    });
  });
}

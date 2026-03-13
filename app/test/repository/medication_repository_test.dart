import 'package:flutter_test/flutter_test.dart';
import 'package:epo_app/data/models/medication.dart';
import 'package:epo_app/repository/medication_repository.dart';

void main() {
  group('MedicationRepository.logIntake', () {
    late MedicationRepository repository;

    setUp(() {
      repository = MedicationRepository();
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
  });
}

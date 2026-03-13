import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:epo_app/ui/app_state.dart';
import 'package:epo_app/data/ble_service.dart';
import 'package:epo_app/repository/medication_repository.dart';
import 'package:epo_app/data/models/medication.dart';

class MockBLEService extends Mock implements BLEService {}
class MockMedicationRepository extends Mock implements MedicationRepository {}

void main() {
  late MockBLEService mockBLEService;
  late MockMedicationRepository mockMedicationRepository;
  late AppState appState;

  late StreamController<BluetoothConnectionState> connectionStateController;
  late StreamController<String> notificationsController;
  late StreamController<List<Medication>> medicationsController;

  setUp(() {
    mockBLEService = MockBLEService();
    mockMedicationRepository = MockMedicationRepository();

    connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
    notificationsController = StreamController<String>.broadcast();
    medicationsController = StreamController<List<Medication>>.broadcast();

    when(() => mockBLEService.connectionState).thenAnswer((_) => connectionStateController.stream);
    when(() => mockBLEService.notifications).thenAnswer((_) => notificationsController.stream);

    when(() => mockMedicationRepository.getMedications()).thenAnswer((_) => medicationsController.stream);

    // allow logIntake to be called
    when(() => mockMedicationRepository.logIntake(any(), medicationId: any(named: 'medicationId')))
        .thenAnswer((_) async {});
  });

  tearDown(() {
    appState.dispose();
    connectionStateController.close();
    notificationsController.close();
    medicationsController.close();
  });

  test('medications are sorted by earliest dose', () async {
    appState = AppState(mockBLEService, mockMedicationRepository);

    int notifyCount = 0;
    appState.addListener(() {
      notifyCount++;
    });

    final med1 = Medication(
      id: '1',
      name: 'Med 1',
      dosage: '10mg',
      stockCount: 10,
      scheduleHours: [14],
      scheduleMinutes: [30],
    ); // 14:30

    final med2 = Medication(
      id: '2',
      name: 'Med 2',
      dosage: '20mg',
      stockCount: 5,
      scheduleHours: [8],
      scheduleMinutes: [15],
    ); // 08:15

    final med3 = Medication(
      id: '3',
      name: 'Med 3',
      dosage: '15mg',
      stockCount: 2,
      scheduleHours: [12],
      scheduleMinutes: [0],
    ); // 12:00

    // Provide meds out of order
    medicationsController.add([med1, med2, med3]);

    // Wait for stream to process
    await Future.delayed(Duration.zero);

    // Should be sorted by time: med2 (08:15), med3 (12:00), med1 (14:30)
    expect(appState.medications.length, 3);
    expect(appState.medications[0].id, '2'); // 8:15
    expect(appState.medications[1].id, '3'); // 12:00
    expect(appState.medications[2].id, '1'); // 14:30

    expect(notifyCount, greaterThan(0));
  });

  test('connectionState is updated from BLEService', () async {
    appState = AppState(mockBLEService, mockMedicationRepository);

    int notifyCount = 0;
    appState.addListener(() {
      notifyCount++;
    });

    expect(appState.connectionState, BluetoothConnectionState.disconnected);

    connectionStateController.add(BluetoothConnectionState.connected);
    await Future.delayed(Duration.zero);

    expect(appState.connectionState, BluetoothConnectionState.connected);
    expect(notifyCount, greaterThan(0));
  });

  test('INTAKE_CONFIRMED notification triggers logIntake with first medication id', () async {
    appState = AppState(mockBLEService, mockMedicationRepository);

    final med1 = Medication(
      id: 'med_first',
      name: 'Med 1',
      dosage: '10mg',
      stockCount: 10,
      scheduleHours: [8],
      scheduleMinutes: [0],
    );

    // Ensure appState has medications
    medicationsController.add([med1]);
    await Future.delayed(Duration.zero);

    // Simulate notification
    notificationsController.add('INTAKE_CONFIRMED');
    await Future.delayed(Duration.zero);

    verify(() => mockMedicationRepository.logIntake('INTAKE_CONFIRMED', medicationId: 'med_first')).called(1);
  });

  test('ALARM_START notification triggers logIntake with first medication id', () async {
    appState = AppState(mockBLEService, mockMedicationRepository);

    final med1 = Medication(
      id: 'med_first',
      name: 'Med 1',
      dosage: '10mg',
      stockCount: 10,
      scheduleHours: [8],
      scheduleMinutes: [0],
    );

    // Ensure appState has medications
    medicationsController.add([med1]);
    await Future.delayed(Duration.zero);

    // Simulate notification
    notificationsController.add('ALARM_START');
    await Future.delayed(Duration.zero);

    verify(() => mockMedicationRepository.logIntake('ALARM_START', medicationId: 'med_first')).called(1);
  });

  test('INTAKE_CONFIRMED notification without medications passes null medicationId', () async {
    appState = AppState(mockBLEService, mockMedicationRepository);

    // Medications list is empty initially
    expect(appState.medications, isEmpty);

    // Simulate notification
    notificationsController.add('INTAKE_CONFIRMED');
    await Future.delayed(Duration.zero);

    verify(() => mockMedicationRepository.logIntake('INTAKE_CONFIRMED', medicationId: null)).called(1);
  });
}

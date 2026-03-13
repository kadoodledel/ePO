import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:epo_app/data/ble_service.dart';

class MockBluetoothDevice extends Mock implements BluetoothDevice {}
class MockBluetoothService extends Mock implements BluetoothService {}
class MockBluetoothCharacteristic extends Mock implements BluetoothCharacteristic {}
class MockGuid extends Mock implements Guid {}
class FakeGuid extends Fake implements Guid {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 1));
  });

  late BLEService bleService;
  late MockBluetoothDevice mockDevice;
  late MockBluetoothService mockService;
  late MockBluetoothCharacteristic mockCharacteristic;
  late StreamController<BluetoothConnectionState> connectionStateController;
  late StreamController<List<int>> lastValueStreamController;

  setUp(() {
    bleService = BLEService();
    mockDevice = MockBluetoothDevice();
    mockService = MockBluetoothService();
    mockCharacteristic = MockBluetoothCharacteristic();
    connectionStateController = StreamController<BluetoothConnectionState>();
    lastValueStreamController = StreamController<List<int>>();

    // Mock Device setup
    when(() => mockDevice.connectionState)
        .thenAnswer((_) => connectionStateController.stream);
    when(() => mockDevice.connect(
          timeout: any(named: 'timeout'),
          mtu: any(named: 'mtu'),
          autoConnect: any(named: 'autoConnect'),
        )).thenAnswer((_) async {});
    when(() => mockDevice.discoverServices(
        timeout: any(named: 'timeout'))).thenAnswer((_) async => [mockService]);

    // Mock Service setup
    final serviceGuid = Guid(BLEService.serviceUuid);
    when(() => mockService.uuid).thenReturn(serviceGuid);
    when(() => mockService.characteristics).thenReturn([mockCharacteristic]);

    // Mock Characteristic setup
    final characteristicGuid = Guid(BLEService.characteristicUuid);
    when(() => mockCharacteristic.uuid).thenReturn(characteristicGuid);
    when(() => mockCharacteristic.setNotifyValue(any(),
        timeout: any(named: 'timeout'),
        forceIndications: any(named: 'forceIndications')))
        .thenAnswer((_) async => true);
    when(() => mockCharacteristic.lastValueStream)
        .thenAnswer((_) => lastValueStreamController.stream);
    when(() => mockCharacteristic.write(any(),
        withoutResponse: any(named: 'withoutResponse'),
        allowLongWrite: any(named: 'allowLongWrite'),
        timeout: any(named: 'timeout')))
        .thenAnswer((_) async {});
  });

  tearDown(() {
    connectionStateController.close();
    lastValueStreamController.close();
    bleService.dispose();
  });

  Future<void> connectAndSetupCharacteristic() async {
    // Start connecting
    final connectFuture = bleService.connect(mockDevice);

    // Simulate connection success
    connectionStateController.add(BluetoothConnectionState.connected);

    // Wait for the asynchronous operations in _onConnected to complete
    await Future.delayed(Duration.zero);

    // Check if the auto syncTime was called in _onConnected
    verify(() => mockCharacteristic.write(any(),
        withoutResponse: any(named: 'withoutResponse'),
        allowLongWrite: any(named: 'allowLongWrite'),
        timeout: any(named: 'timeout'))).called(1);

    clearInteractions(mockCharacteristic);
  }

  test('syncTime sends correct T command', () async {
    await connectAndSetupCharacteristic();

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await bleService.syncTime();

    final captured = verify(() => mockCharacteristic.write(captureAny(),
        withoutResponse: any(named: 'withoutResponse'),
        allowLongWrite: any(named: 'allowLongWrite'),
        timeout: any(named: 'timeout'))).captured;

    expect(captured.length, 1);
    final sentData = utf8.decode(captured.first);
    expect(sentData.startsWith('T'), isTrue);
    final sentEpoch = int.parse(sentData.substring(1));
    // Verify epoch is close to current time (allow 2 seconds delta)
    expect((sentEpoch - now).abs(), lessThanOrEqualTo(2));
  });

  test('setAlarm sends correct A command with padding', () async {
    await connectAndSetupCharacteristic();

    await bleService.setAlarm(8, 5);

    final captured = verify(() => mockCharacteristic.write(captureAny(),
        withoutResponse: any(named: 'withoutResponse'),
        allowLongWrite: any(named: 'allowLongWrite'),
        timeout: any(named: 'timeout'))).captured;

    expect(captured.length, 1);
    expect(utf8.decode(captured.first), 'A08:05');
  });

  test('setDuration sends correct D command', () async {
    await connectAndSetupCharacteristic();

    await bleService.setDuration(30);

    final captured = verify(() => mockCharacteristic.write(captureAny(),
        withoutResponse: any(named: 'withoutResponse'),
        allowLongWrite: any(named: 'allowLongWrite'),
        timeout: any(named: 'timeout'))).captured;

    expect(captured.length, 1);
    expect(utf8.decode(captured.first), 'D30');
  });

  test('setReminderInterval sends correct R command', () async {
    await connectAndSetupCharacteristic();

    await bleService.setReminderInterval(15);

    final captured = verify(() => mockCharacteristic.write(captureAny(),
        withoutResponse: any(named: 'withoutResponse'),
        allowLongWrite: any(named: 'allowLongWrite'),
        timeout: any(named: 'timeout'))).captured;

    expect(captured.length, 1);
    expect(utf8.decode(captured.first), 'R15');
  });
}

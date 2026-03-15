import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:epo_app/data/models/medication.dart';

class BLEService {
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _mainCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

  final _connectionController = StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionState => _connectionController.stream;

  final _notificationController = StreamController<String>.broadcast();
  Stream<String> get notifications => _notificationController.stream;

  Future<void> startScan() async {
    await FlutterBluePlus.startScan(
      withServices: [Guid(serviceUuid)],
      timeout: const Duration(seconds: 15),
    );
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> connect(BluetoothDevice device) async {
    _connectedDevice = device;
    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      _connectionController.add(state);
      if (state == BluetoothConnectionState.connected) {
        _reconnectAttempts = 0;
        _onConnected(device);
      } else if (state == BluetoothConnectionState.disconnected && _connectedDevice != null) {
        _scheduleReconnect(device);
      }
    });

    await device.connect();
  }

  void _scheduleReconnect(BluetoothDevice device) {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    final delaySeconds = 3 * (1 << (_reconnectAttempts - 1)); // 3s, 6s, 12s
    Future.delayed(Duration(seconds: delaySeconds), () async {
      if (_connectedDevice != null) {
        await device.connect();
      }
    });
  }

  Future<void> _onConnected(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    final serviceUuidLower = serviceUuid.toLowerCase();
    final characteristicUuidLower = characteristicUuid.toLowerCase();

    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUuidLower) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() == characteristicUuidLower) {
            _mainCharacteristic = characteristic;

            // Enable notifications
            await characteristic.setNotifyValue(true);
            _notificationSubscription?.cancel();
            _notificationSubscription = characteristic.lastValueStream.listen((value) {
              String message = utf8.decode(value);
              if (message.isNotEmpty) {
                _notificationController.add(message);
              }
            });

            // Auto Time Sync
            await syncTime();
            break;
          }
        }
      }
    }
  }

  Future<void> syncTime() async {
    if (_mainCharacteristic == null) return;
    int epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _sendCommand("T$epoch");
  }

  Future<void> syncMedication(Medication medication) async {
    // TODO: [Technical Debt] Implement multi-slot individual medication hardware sync.
    // For the prototype, we assume a single hardware slot and sync the first scheduled time.
    if (medication.scheduleHours.isNotEmpty && medication.scheduleMinutes.isNotEmpty) {
      await setAlarm(medication.scheduleHours.first, medication.scheduleMinutes.first);
    }
  }

  Future<void> setAlarm(int hour, int minute) async {
    String h = hour.toString().padLeft(2, '0');
    String m = minute.toString().padLeft(2, '0');
    await _sendCommand("A$h:$m");
  }

  Future<void> setDuration(int seconds) async {
    await _sendCommand("D$seconds");
  }

  Future<void> setReminderInterval(int minutes) async {
    await _sendCommand("R$minutes");
  }

  Future<void> _sendCommand(String command) async {
    if (_mainCharacteristic != null) {
      await _mainCharacteristic!.write(utf8.encode(command));
    }
  }

  Future<void> disconnect() async {
    _reconnectAttempts = _maxReconnectAttempts; // Prevent auto-reconnect on manual disconnect
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _mainCharacteristic = null;
    _connectionSubscription?.cancel();
    _notificationSubscription?.cancel();
  }

  void dispose() {
    _connectionController.close();
    _notificationController.close();
  }
}

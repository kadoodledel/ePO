import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _mainCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;

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
        _onConnected(device);
      }
    });

    await device.connect();
  }

  Future<void> _onConnected(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
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

/**
 * @file BLEManager.cpp
 * @brief Implementation of BLEManager for ePO.
 * @author Jules
 */

#include "BLEManager.h"

void BLEManagerCallbacks::onWrite(BLECharacteristic* pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    if (value.length() > 0) {
        _manager->handleReceivedData(String(value.c_str()));
    }
}

BLEManager::BLEManager()
    : _pServer(nullptr), _pCharacteristic(nullptr),
      _deviceConnected(false), _onTimeReceived(nullptr), _onAlarmReceived(nullptr),
      _onDurationReceived(nullptr), _onReminderReceived(nullptr) {}

void BLEManager::begin() {
    BLEDevice::init(DEVICE_NAME);
    _pServer = BLEDevice::createServer();
    _pServer->setCallbacks(new MyServerCallbacks(this));

    BLEService* pService = _pServer->createService(SERVICE_UUID);

    _pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_WRITE |
        BLECharacteristic::PROPERTY_NOTIFY
    );

    _pCharacteristic->setCallbacks(new BLEManagerCallbacks(this));
    _pCharacteristic->addDescriptor(new BLE2902());

    pService->start();

    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();
}

void BLEManager::sendNotification(String message) {
    if (_deviceConnected && _pCharacteristic) {
        _pCharacteristic->setValue(message.c_str());
        _pCharacteristic->notify();
    }
}

void BLEManager::handleReceivedData(String data) {
    data.trim();
    if (data.startsWith("T")) {
        // Time synchronization: T1672531200
        unsigned long epoch = data.substring(1).toInt();
        if (epoch > 0 && _onTimeReceived) {
            _onTimeReceived(epoch);
        }
    } else if (data.startsWith("A")) {
        // Alarm setting: A08:30 or A8:30
        int colonIndex = data.indexOf(':');
        if (colonIndex != -1) {
            int hour = data.substring(1, colonIndex).toInt();
            int minute = data.substring(colonIndex + 1).toInt();
            if (_onAlarmReceived) {
                _onAlarmReceived(hour, minute);
            }
        }
    } else if (data.startsWith("D")) {
        // Duration setting: D60
        int duration = data.substring(1).toInt();
        if (_onDurationReceived) {
            _onDurationReceived(duration);
        }
    } else if (data.startsWith("R")) {
        // Reminder Interval setting: R15
        int interval = data.substring(1).toInt();
        if (_onReminderReceived) {
            _onReminderReceived(interval);
        }
    }
}

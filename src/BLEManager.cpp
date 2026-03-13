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
      _deviceConnected(false), _onTimeReceived(nullptr), _onAlarmReceived(nullptr) {}

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
        // Alarm setting: A08:30
        int hour = data.substring(1, 3).toInt();
        int minute = data.substring(4, 6).toInt();
        if (_onAlarmReceived) {
            _onAlarmReceived(hour, minute);
        }
    }
}

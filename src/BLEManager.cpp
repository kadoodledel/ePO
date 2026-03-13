/**
 * @file BLEManager.cpp
 * @brief Implementation of BLEManager for ePO.
 * @author Jules
 */

#include "BLEManager.h"
#include <BLESecurity.h>
#include <cstdlib>

void BLEManagerCallbacks::onWrite(BLECharacteristic* pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    if (value.length() > 0) {
        _manager->handleReceivedData(value.c_str());
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
    _pCharacteristic->setAccessPermissions(ESP_GATT_PERM_READ_ENCRYPTED | ESP_GATT_PERM_WRITE_ENCRYPTED);

    _pCharacteristic->setCallbacks(new BLEManagerCallbacks(this));
    _pCharacteristic->addDescriptor(new BLE2902());

    pService->start();

    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();

    BLESecurity* pSecurity = new BLESecurity();
    pSecurity->setAuthenticationMode(ESP_LE_AUTH_REQ_SC_BOND);
    pSecurity->setCapability(ESP_IO_CAP_NONE);
    pSecurity->setInitEncryptionKey(ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK);
}

void BLEManager::sendNotification(const String& message) {
    if (_deviceConnected && _pCharacteristic) {
        _pCharacteristic->setValue(message);
        _pCharacteristic->notify();
    }
}

void BLEManager::handleReceivedData(const char* data) {
    const char* ptr = data;
    // Skip leading whitespace (similar to trim but without modifying the string or copying)
    while (*ptr == ' ' || *ptr == '\t' || *ptr == '\n' || *ptr == '\r') {
        ptr++;
    }

    if (*ptr == 'T') {
        // Time synchronization: T1672531200
        unsigned long epoch = strtoul(ptr + 1, nullptr, 10);
        if (epoch > 0 && _onTimeReceived) {
            _onTimeReceived(epoch);
        }
    } else if (*ptr == 'A') {
        // Alarm setting: A08:30 or A8:30
        char* endptr;
        int hour = (int)strtol(ptr + 1, &endptr, 10);
        if (*endptr == ':') {
            int minute = (int)strtol(endptr + 1, nullptr, 10);
            if (_onAlarmReceived) {
                _onAlarmReceived(hour, minute);
            }
        }
    } else if (*ptr == 'D') {
        // Duration setting: D60
        int duration = (int)strtol(ptr + 1, nullptr, 10);
        if (duration >= 1 && duration <= 3600) {
            if (_onDurationReceived) {
                _onDurationReceived(duration);
            }
        }
    } else if (*ptr == 'R') {
        // Reminder Interval setting: R15
        int interval = (int)strtol(ptr + 1, nullptr, 10);
        if (interval >= 1 && interval <= 1440) {
            if (_onReminderReceived) {
                _onReminderReceived(interval);
            }
        }
    }
}

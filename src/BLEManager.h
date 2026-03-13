/**
 * @file BLEManager.h
 * @brief Handles BLE communication for ePO.
 * @author Jules
 */

#ifndef BLE_MANAGER_H
#define BLE_MANAGER_H

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "Constants.h"

class BLEManagerCallbacks : public BLECharacteristicCallbacks {
public:
    BLEManagerCallbacks(class BLEManager* manager) : _manager(manager) {}
    void onWrite(BLECharacteristic* pCharacteristic) override;

private:
    class BLEManager* _manager;
};

class BLEManager {
public:
    BLEManager();

    /**
     * @brief Starts the BLE server and advertising.
     */
    void begin();

    /**
     * @brief Sends a notification to the connected client.
     * @param message Message to send.
     */
    void sendNotification(const char* message);

    /**
     * @brief Processed received data from BLE client.
     * Called by BLEManagerCallbacks.
     */
    void handleReceivedData(const char* data);

    // Callbacks for application logic
    void setOnTimeReceived(void (*callback)(unsigned long)) { _onTimeReceived = callback; }
    void setOnAlarmReceived(void (*callback)(int, int)) { _onAlarmReceived = callback; }
    void setOnDurationReceived(void (*callback)(int)) { _onDurationReceived = callback; }
    void setOnReminderReceived(void (*callback)(int)) { _onReminderReceived = callback; }

    bool isConnected() { return _deviceConnected; }

private:
    BLEServer* _pServer;
    BLECharacteristic* _pCharacteristic;
    bool _deviceConnected;

    void (*_onTimeReceived)(unsigned long);
    void (*_onAlarmReceived)(int, int);
    void (*_onDurationReceived)(int);
    void (*_onReminderReceived)(int);

    friend class BLEServerCallbacks;
    class MyServerCallbacks : public BLEServerCallbacks {
        BLEManager* _m;
    public:
        MyServerCallbacks(BLEManager* m) : _m(m) {}
        void onConnect(BLEServer* pServer) override { _m->_deviceConnected = true; }
        void onDisconnect(BLEServer* pServer) override {
            _m->_deviceConnected = false;
            BLEDevice::startAdvertising(); // Restart advertising
        }
    };
};

#endif // BLE_MANAGER_H

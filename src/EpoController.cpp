/**
 * @file EpoController.cpp
 * @brief Implementation of EpoController for ePO.
 * @author Jules
 */

#include "EpoController.h"

EpoController* EpoController::_instance = nullptr;

EpoController::EpoController()
    : _state(SystemState::IDLE), _lastAlarmCheck(0),
      _lastBlinkTime(0), _snoozeStartTime(0) {
    _instance = this;
}

void EpoController::begin() {
    _hw.begin();
    _alarm.begin();

    _ble.setOnTimeReceived(onTimeSync);
    _ble.setOnAlarmReceived(onAlarmSet);
    _ble.begin();
}

void EpoController::update() {
    _hw.update();

    // Notify BLE on Reed Switch Change
    if (_hw.hasReedStateChanged()) {
        String msg = _hw.isReedClosed() ? "REED_CLOSED" : "REED_OPEN";
        _ble.sendNotification(msg);

        // Requirement: Stop alert immediately when Reed switch goes Closed -> Open
        if (_state == SystemState::ALERT && !_hw.isReedClosed()) {
            stopAlert();
        }
    }

    // State Machine
    switch (_state) {
        case SystemState::IDLE:
            handleIdleState();
            break;
        case SystemState::ALERT:
            handleAlertState();
            break;
        case SystemState::SNOOZED:
            handleSnoozedState();
            break;
    }
}

void EpoController::handleIdleState() {
    if (millis() - _lastAlarmCheck > ALARM_CHECK_INTERVAL) {
        _lastAlarmCheck = millis();
        if (_alarm.isAlarmTime(_time.getHour(), _time.getMinute())) {
            startAlert();
        }
    }
}

void EpoController::handleAlertState() {
    // Blink LED and Buzzer
    if (millis() - _lastBlinkTime > BLINK_INTERVAL) {
        _lastBlinkTime = millis();
        _hw.toggleAlertPeripherals();
    }

    // Secondary interaction: Snooze via Touch
    if (_hw.isTouched()) {
        snoozeAlert();
    }
}

void EpoController::handleSnoozedState() {
    // Snooze for 5 minutes (300,000 ms)
    if (millis() - _snoozeStartTime > 300000) {
        startAlert();
    }

    // Can still stop via Reed switch (handled in update's common part)
}

void EpoController::startAlert() {
    _state = SystemState::ALERT;
    _hw.setAlertState(true);
    _ble.sendNotification("ALARM_START");
}

void EpoController::stopAlert() {
    _state = SystemState::IDLE;
    _hw.setAlertState(false);
    _ble.sendNotification("ALARM_STOP");
}

void EpoController::snoozeAlert() {
    _state = SystemState::SNOOZED;
    _hw.setAlertState(false);
    _snoozeStartTime = millis();
    _ble.sendNotification("ALARM_SNOOZE");
}

// Static Callbacks
void EpoController::onTimeSync(unsigned long epoch) {
    if (_instance) {
        _instance->_time.setTime(epoch);
        _instance->_ble.sendNotification("TIME_SYNCED");
    }
}

void EpoController::onAlarmSet(int hour, int minute) {
    if (_instance) {
        _instance->_alarm.setAlarm(hour, minute);
        _instance->_ble.sendNotification("ALARM_SET_OK");
    }
}

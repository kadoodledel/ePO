/**
 * @file HardwareManager.cpp
 * @brief Implementation of HardwareManager for ePO.
 * @author Jules
 */

#include "HardwareManager.h"

HardwareManager::HardwareManager()
    : _lastReedState(HIGH), _currentReedState(HIGH),
      _lastReedDebounceTime(0), _reedChanged(false),
      _alertActive(false), _peripheralState(false) {}

void HardwareManager::begin() {
    pinMode(PIN_REED_SWITCH, INPUT_PULLUP);
    pinMode(PIN_PIEZO_BUZZER, OUTPUT);
    pinMode(PIN_INTERNAL_LED, OUTPUT);

    digitalWrite(PIN_PIEZO_BUZZER, LOW);
    digitalWrite(PIN_INTERNAL_LED, LOW);

    _currentReedState = digitalRead(PIN_REED_SWITCH);
    _lastReedState = _currentReedState;
}

void HardwareManager::update() {
    // Reed Switch Debouncing
    bool reading = digitalRead(PIN_REED_SWITCH);

    if (reading != _lastReedState) {
        _lastReedDebounceTime = millis();
    }

    if ((millis() - _lastReedDebounceTime) > DEBOUNCE_DELAY) {
        if (reading != _currentReedState) {
            _currentReedState = reading;
            _reedChanged = true;
        }
    }

    _lastReedState = reading;
}

bool HardwareManager::hasReedStateChanged() {
    if (_reedChanged) {
        _reedChanged = false;
        return true;
    }
    return false;
}

bool HardwareManager::isReedClosed() {
    // Assuming LOW means closed for INPUT_PULLUP reed switch
    return (_currentReedState == LOW);
}

bool HardwareManager::isTouched() {
    // touchRead returns a value; lower values typically mean touch
    return (touchRead(PIN_TOUCH_SENSOR) < TOUCH_THRESHOLD);
}

void HardwareManager::setAlertState(bool on) {
    _alertActive = on;
    if (!on) {
        _peripheralState = false;
        digitalWrite(PIN_INTERNAL_LED, LOW);
        digitalWrite(PIN_PIEZO_BUZZER, LOW);
    }
}

void HardwareManager::toggleAlertPeripherals() {
    if (_alertActive) {
        _peripheralState = !_peripheralState;
        digitalWrite(PIN_INTERNAL_LED, _peripheralState ? HIGH : LOW);
        digitalWrite(PIN_PIEZO_BUZZER, _peripheralState ? HIGH : LOW);
    }
}

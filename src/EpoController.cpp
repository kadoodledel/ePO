/**
 * @file EpoController.cpp
 * @brief Implementation of EpoController for ePO.
 * @author Jules
 */

#include "EpoController.h"

EpoController* EpoController::_instance = nullptr;

// Persistent across deep sleep
RTC_DATA_ATTR bool bootIsReReminder = false;
RTC_DATA_ATTR int bootLastTriggeredMinute = -1;

EpoController::EpoController()
    : _state(SystemState::IDLE),
      _lastBlinkTime(0), _alertStartTime(0),
      _isReReminder(false), _intakeSuccess(false) {
    _instance = this;
}

void EpoController::begin() {
    _hw.begin();
    _alarm.begin();

    _ble.setOnTimeReceived(onTimeSync);
    _ble.setOnAlarmReceived(onAlarmSet);
    _ble.setOnDurationReceived(onDurationSet);
    _ble.setOnReminderReceived(onReminderSet);
    _ble.begin();

    esp_sleep_wakeup_cause_t wakeup_reason = esp_sleep_get_wakeup_cause();

    if (wakeup_reason == ESP_SLEEP_WAKEUP_TIMER) {
        // Triggered by alarm or reminder timer
        _isReReminder = bootIsReReminder;
        startAlert(_isReReminder);
    } else if (wakeup_reason == ESP_SLEEP_WAKEUP_EXT0 || wakeup_reason == ESP_SLEEP_WAKEUP_TOUCHPAD) {
        // Wakeup by interaction (Reed or Touch)
        // Check for intake success even if not currently in ALERT state (user might have interacted early)
        _state = SystemState::IDLE;
    }
}

void EpoController::update() {
    _hw.update();

    // Notify BLE on Reed Switch Change
    if (_hw.hasReedStateChanged()) {
        String msg = _hw.isReedClosed() ? "REED_CLOSED" : "REED_OPEN";
        _ble.sendNotification(msg);
    }

    // State Machine
    switch (_state) {
        case SystemState::IDLE:
            handleIdleState();
            break;
        case SystemState::ALERT:
            handleAlertState();
            break;
        case SystemState::WAITING_FOR_RETRY:
            handleWaitingForRetryState();
            break;
    }
}

void EpoController::handleIdleState() {
    // Check if it's already time for an alarm (if we didn't wake up via timer)
    int currentMinute = _time.getMinute();
    if (currentMinute != bootLastTriggeredMinute && _alarm.isAlarmTime(_time.getHour(), currentMinute)) {
        bootLastTriggeredMinute = currentMinute;
        startAlert(false);
        return;
    }

    // If everything is idle and no interaction for a bit, go to deep sleep
    if (millis() > 10000 && !_ble.isConnected()) {
        enterDeepSleep();
    }
}

void EpoController::handleAlertState() {
    // Blink LED and Buzzer
    if (millis() - _lastBlinkTime > BLINK_INTERVAL) {
        _lastBlinkTime = millis();
        _hw.toggleAlertPeripherals();
    }

    // Verification: Intake confirmed if isTouched() AND !isReedClosed()
    if (_hw.isTouched() && !_hw.isReedClosed()) {
        _intakeSuccess = true;
        _ble.sendNotification("INTAKE_CONFIRMED");
        stopAlert();
        return;
    }

    // Timeout check
    if (millis() - _alertStartTime > (unsigned long)_alarm.getAlarmDuration() * 1000) {
        _ble.sendNotification("ALARM_TIMEOUT");
        _state = SystemState::WAITING_FOR_RETRY;
        _hw.setAlertState(false);
    }
}

void EpoController::handleWaitingForRetryState() {
    // If not connected to BLE, go to sleep and wait for reminder
    if (!_ble.isConnected()) {
        enterDeepSleep();
    }
}

void EpoController::startAlert(bool isReReminder) {
    _state = SystemState::ALERT;
    _isReReminder = isReReminder;
    if (!isReReminder) {
        bootLastTriggeredMinute = _time.getMinute();
    }
    _alertStartTime = millis();
    _intakeSuccess = false;
    _hw.setAlertState(true);

    if (isReReminder) {
        _ble.sendNotification("ALARM_RE_REMINDER");
    } else {
        _ble.sendNotification("ALARM_START");
    }
}

void EpoController::stopAlert() {
    _state = SystemState::IDLE;
    _hw.setAlertState(false);
    _ble.sendNotification("ALARM_STOP");
    if (_intakeSuccess) {
        _ble.sendNotification("INTAKE_SUCCESS");
        bootIsReReminder = false; // Reset for next day
    }
}

void EpoController::enterDeepSleep() {
    long sleepSeconds = 0;

    if (_state == SystemState::WAITING_FOR_RETRY) {
        // Next wake up is for re-reminder
        sleepSeconds = (long)_alarm.getReminderInterval() * 60;
        bootIsReReminder = true;
    } else {
        // Next wake up is for regular alarm
        sleepSeconds = _alarm.getSecondsUntilNextAlarm(_time.getHour(), _time.getMinute(), 0); // approx
        bootIsReReminder = false;
    }

    if (sleepSeconds > 0) {
        esp_sleep_enable_timer_wakeup(sleepSeconds * 1000000ULL);
        _hw.setupSleepWakeup();
        _ble.sendNotification("ENTERING_SLEEP");
        delay(100); // Give some time for BLE notification to be sent
        esp_deep_sleep_start();
    }
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

void EpoController::onDurationSet(int seconds) {
    if (_instance) {
        _instance->_alarm.setAlarmDuration(seconds);
        _instance->_ble.sendNotification("DURATION_SET_OK");
    }
}

void EpoController::onReminderSet(int minutes) {
    if (_instance) {
        _instance->_alarm.setReminderInterval(minutes);
        _instance->_ble.sendNotification("REMINDER_SET_OK");
    }
}

/**
 * @file EpoController.h
 * @brief Orchestrates ePO pill box logic and state transitions.
 * @author Jules
 */

#ifndef EPO_CONTROLLER_H
#define EPO_CONTROLLER_H

#include "HardwareManager.h"
#include "TimeManager.h"
#include "AlarmManager.h"
#include "BLEManager.h"

enum class SystemState {
    IDLE,
    ALERT,
    WAITING_FOR_RETRY
};

class EpoController {
public:
    EpoController();

    void begin();
    void update();

    // Callbacks for BLE actions
    static void onTimeSync(unsigned long epoch);
    static void onAlarmSet(int hour, int minute);
    static void onDurationSet(int seconds);
    static void onReminderSet(int minutes);

private:
    void handleIdleState();
    void handleAlertState();
    void handleWaitingForRetryState();

    void startAlert(bool isReReminder);
    void stopAlert();
    void enterDeepSleep();

    HardwareManager _hw;
    TimeManager _time;
    AlarmManager _alarm;
    BLEManager _ble;

    SystemState _state;
    unsigned long _lastBlinkTime;
    unsigned long _alertStartTime;

    bool _isReReminder;
    bool _intakeSuccess;

    static EpoController* _instance;
};

#endif // EPO_CONTROLLER_H

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
    SNOOZED
};

class EpoController {
public:
    EpoController();

    void begin();
    void update();

    // Callbacks for BLE actions
    static void onTimeSync(unsigned long epoch);
    static void onAlarmSet(int hour, int minute);

private:
    void handleIdleState();
    void handleAlertState();
    void handleSnoozedState();

    void startAlert();
    void stopAlert();
    void snoozeAlert();

    HardwareManager _hw;
    TimeManager _time;
    AlarmManager _alarm;
    BLEManager _ble;

    SystemState _state;
    unsigned long _lastAlarmCheck;
    unsigned long _lastBlinkTime;
    unsigned long _snoozeStartTime;

    static EpoController* _instance;
};

#endif // EPO_CONTROLLER_H

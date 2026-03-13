/**
 * @file AlarmManager.h
 * @brief Manages pill schedules and persistence for ePO.
 * @author Jules
 */

#ifndef ALARM_MANAGER_H
#define ALARM_MANAGER_H

#include <Preferences.h>
#include "Constants.h"

class AlarmManager {
public:
    AlarmManager();

    /**
     * @brief Initializes preferences and loads stored alarm.
     */
    void begin();

    /**
     * @brief Sets a new alarm time and saves to NVS.
     * @param hour Hour (0-23).
     * @param minute Minute (0-59).
     */
    void setAlarm(int hour, int minute);

    /**
     * @brief Checks if an alarm should be triggered now.
     * @param currentHour Current hour from RTC.
     * @param currentMinute Current minute from RTC.
     * @return true if it's time for the alarm.
     */
    bool isAlarmTime(int currentHour, int currentMinute);

    int getAlarmHour() { return _alarmHour; }
    int getAlarmMinute() { return _alarmMinute; }

private:
    Preferences _prefs;
    int _alarmHour;
    int _alarmMinute;
    bool _alarmTriggeredToday;
    int _lastCheckedMinute;
};

#endif // ALARM_MANAGER_H

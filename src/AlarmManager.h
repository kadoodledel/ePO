/**
 * @file AlarmManager.h
 * @brief Manages pill schedules and persistence for ePO.
 * @author Jules
 */

#ifndef ALARMMANAGER_H
#define ALARMMANAGER_H

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

    void setAlarmDuration(int seconds);
    void setReminderInterval(int minutes);

    /**
     * @brief Checks if an alarm should be triggered now.
     * @param currentHour Current hour from RTC.
     * @param currentMinute Current minute from RTC.
     * @return true if it's time for the alarm.
     */
    bool isAlarmTime(int currentHour, int currentMinute);

    /**
     * @brief Calculates seconds until the next occurrence of the alarm.
     * @param currentHour Current hour.
     * @param currentMinute Current minute.
     * @param currentSecond Current second.
     * @return Seconds until next alarm.
     */
    long getSecondsUntilNextAlarm(int currentHour, int currentMinute, int currentSecond);

    int getAlarmHour() { return _alarmHour; }
    int getAlarmDuration() { return _alarmDuration; }
    int getReminderInterval() { return _reminderInterval; }

private:
    Preferences _prefs;
    int _alarmHour;
    int _alarmMinute;
    int _alarmDuration;
    int _reminderInterval;
    bool _alarmTriggeredToday;
    int _lastCheckedMinute;
};

#endif // ALARMMANAGER_H

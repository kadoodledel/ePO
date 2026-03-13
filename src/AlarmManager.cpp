/**
 * @file AlarmManager.cpp
 * @brief Implementation of AlarmManager for ePO.
 * @author Jules
 */

#include "AlarmManager.h"

AlarmManager::AlarmManager()
    : _alarmHour(-1), _alarmMinute(-1),
      _alarmTriggeredToday(false), _lastCheckedMinute(-1) {}

void AlarmManager::begin() {
    _prefs.begin(PREF_NAMESPACE, false);
    _alarmHour = _prefs.getInt(PREF_ALARM_HOUR, -1);
    _alarmMinute = _prefs.getInt(PREF_ALARM_MINUTE, -1);
}

void AlarmManager::setAlarm(int hour, int minute) {
    if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        _alarmHour = hour;
        _alarmMinute = minute;
        _prefs.putInt(PREF_ALARM_HOUR, _alarmHour);
        _prefs.putInt(PREF_ALARM_MINUTE, _alarmMinute);
        _alarmTriggeredToday = false; // Reset when new alarm is set
    }
}

bool AlarmManager::isAlarmTime(int currentHour, int currentMinute) {
    // Reset trigger flag at midnight or if minute changed back (rare)
    if (currentMinute != _lastCheckedMinute) {
        if (currentHour == 0 && currentMinute == 0) {
            _alarmTriggeredToday = false;
        }
        _lastCheckedMinute = currentMinute;
    }

    if (_alarmHour == -1 || _alarmMinute == -1) return false;

    if (currentHour == _alarmHour && currentMinute == _alarmMinute) {
        if (!_alarmTriggeredToday) {
            _alarmTriggeredToday = true;
            return true;
        }
    } else {
        // If it's no longer the alarm minute, we could potentially reset the flag
        // but for a once-a-day alarm, resetting at midnight is safer.
        // If we want to allow multiple alarms or snooze, this logic would be more complex.
    }

    return false;
}

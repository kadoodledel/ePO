/**
 * @file AlarmManager.cpp
 * @brief Implementation of AlarmManager for ePO.
 * @author Jules
 */

#include "AlarmManager.h"

AlarmManager::AlarmManager()
    : _alarmHour(-1), _alarmMinute(-1),
      _alarmDuration(DEFAULT_ALARM_DURATION),
      _reminderInterval(DEFAULT_REMINDER_INTERVAL),
      _alarmTriggeredToday(false), _lastCheckedMinute(-1) {}

void AlarmManager::begin() {
    _prefs.begin(PREF_NAMESPACE, false);
    _alarmHour = _prefs.getInt(PREF_ALARM_HOUR, -1);
    _alarmMinute = _prefs.getInt(PREF_ALARM_MINUTE, -1);
    _alarmDuration = _prefs.getInt(PREF_ALARM_DURATION, DEFAULT_ALARM_DURATION);
    _reminderInterval = _prefs.getInt(PREF_REMINDER_INT, DEFAULT_REMINDER_INTERVAL);
}

void AlarmManager::setAlarm(int hour, int minute) {
    if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        if (hour != _alarmHour || minute != _alarmMinute) {
            _alarmHour = hour;
            _alarmMinute = minute;
            _prefs.putInt(PREF_ALARM_HOUR, _alarmHour);
            _prefs.putInt(PREF_ALARM_MINUTE, _alarmMinute);
            _alarmTriggeredToday = false; // Reset when new alarm is set
        }
    }
}

void AlarmManager::setAlarmDuration(int seconds) {
    if (seconds > 0 && seconds != _alarmDuration) {
        _alarmDuration = seconds;
        _prefs.putInt(PREF_ALARM_DURATION, _alarmDuration);
    }
}

void AlarmManager::setReminderInterval(int minutes) {
    if (minutes > 0 && minutes != _reminderInterval) {
        _reminderInterval = minutes;
        _prefs.putInt(PREF_REMINDER_INT, _reminderInterval);
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
    }

    return false;
}

long AlarmManager::getSecondsUntilNextAlarm(int currentHour, int currentMinute, int currentSecond) {
    if (_alarmHour == -1 || _alarmMinute == -1) return -1;

    long currentSecondsSinceMidnight = (long)currentHour * 3600 + (long)currentMinute * 60 + currentSecond;
    long alarmSecondsSinceMidnight = (long)_alarmHour * 3600 + (long)_alarmMinute * 60;

    long diff = alarmSecondsSinceMidnight - currentSecondsSinceMidnight;
    if (diff <= 0) {
        // Alarm is tomorrow
        diff += 24 * 3600;
    }

    return diff;
}

/**
 * @file TimeManager.cpp
 * @brief Implementation of TimeManager for ePO.
 * @author Jules
 */

#include "TimeManager.h"

TimeManager::TimeManager() : _rtc(0) {}

void TimeManager::setTime(unsigned long epoch) {
    _rtc.setTime(epoch);
}

int TimeManager::getHour() {
    return _rtc.getHour(true); // 24h format
}

int TimeManager::getMinute() {
    return _rtc.getMinute();
}

String TimeManager::getTimeString() {
    return _rtc.getTime("%H:%M:%S");
}

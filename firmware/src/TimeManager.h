/**
 * @file TimeManager.h
 * @brief Manages internal RTC for the ePO pill box.
 * @author Jules
 */

#ifndef TIME_MANAGER_H
#define TIME_MANAGER_H

#include <ESP32Time.h>
#include "Constants.h"

class TimeManager {
public:
    TimeManager();

    /**
     * @brief Sets the internal RTC time.
     * @param epoch Unix timestamp.
     */
    void setTime(unsigned long epoch);

    /**
     * @brief Gets current hour (0-23).
     */
    int getHour();

    /**
     * @brief Gets current minute (0-59).
     */
    int getMinute();

    /**
     * @brief Gets current second (0-59).
     */
    int getSecond();

    /**
     * @brief Formats current time as string.
     */
    String getTimeString();

private:
    ESP32Time _rtc;
};

#endif // TIME_MANAGER_H

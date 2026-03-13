/**
 * @file HardwareManager.h
 * @brief Handles physical peripherals for the ePO pill box.
 * @author Jules
 */

#ifndef HARDWARE_MANAGER_H
#define HARDWARE_MANAGER_H

#include "Constants.h"

class HardwareManager {
public:
    HardwareManager();

    /**
     * @brief Initializes GPIO pins and peripherals.
     */
    void begin();

    /**
     * @brief Updates sensor states and handles debouncing.
     * Should be called frequently in the main loop.
     */
    void update();

    /**
     * @brief Checks if the reed switch state has changed.
     * @return true if state changed since last check.
     */
    bool hasReedStateChanged();

    /**
     * @brief Gets current (debounced) reed switch state.
     * @return true if closed, false if open.
     */
    bool isReedClosed();

    /**
     * @brief Checks if the touch sensor is being triggered.
     * @return true if touched.
     */
    bool isTouched();

    /**
     * @brief Controls the alert peripherals (LED + Buzzer).
     * @param on True to enable alert effects, false to disable.
     */
    void setAlertState(bool on);

    /**
     * @brief Toggles the LED and Buzzer for blinking effect.
     * Called by the controller when in alert state.
     */
    void toggleAlertPeripherals();

private:
    bool _lastReedState;
    bool _currentReedState;
    unsigned long _lastReedDebounceTime;

    bool _reedChanged;

    bool _alertActive;
    bool _peripheralState;
};

#endif // HARDWARE_MANAGER_H

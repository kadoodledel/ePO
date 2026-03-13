/**
 * @file Constants.h
 * @brief Global constants and configuration for the ePO Smart Pill Box.
 * @author Jules
 */

#ifndef CONSTANTS_H
#define CONSTANTS_H

#include <Arduino.h>

// --- Hardware Pins ---
#define PIN_REED_SWITCH     13
#define PIN_TOUCH_SENSOR    4
#define PIN_PIEZO_BUZZER    14
#define PIN_INTERNAL_LED    2

// --- BLE Configuration ---
#define DEVICE_NAME         "ePO Smart Pill Box"
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// --- Logic Constants ---
#define DEBOUNCE_DELAY      50      // ms
#define TOUCH_THRESHOLD     40      // Threshold for ESP32 touch sensor
#define ALARM_CHECK_INTERVAL 1000   // ms
#define BLINK_INTERVAL      500     // ms

// --- Persistence Keys ---
#define PREF_NAMESPACE      "epo_storage"
#define PREF_ALARM_HOUR     "alarm_h"
#define PREF_ALARM_MINUTE   "alarm_m"

#endif // CONSTANTS_H

# ePO - Smart Pill Box Firmware

ePO is a production-ready, modular firmware for an ESP32-based smart pill box. It manages medication schedules, provides haptic/visual alerts, and confirms intake via sensor fusion.

## Features
- **BLE Connectivity**: Synchronize time, set alarms, and configure reminder parameters.
- **Persistence**: Alarm settings and device configuration survive power cycles.
- **Advanced Power Management**: Utilizes Deep Sleep with multiple wake-up sources (Timer, Reed Switch, Touch).
- **Intake Confirmation**: Uses a combination of a Reed switch (opening the box) and a Touch sensor to verify medication intake.
- **Re-reminder Logic**: If intake is not detected within the alarm duration, the device will sleep and re-trigger an alert after a configurable interval.

## BLE Interface
Custom Service UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
Characteristic UUID: `beb5483e-36e1-4688-b7f5-ea07361b26a8`

### Commands (Write)
- `T<timestamp>`: Synchronize Unix timestamp (e.g., `T1672531200`).
- `A<HH:MM>`: Set daily alarm time (e.g., `A08:30`).
- `D<seconds>`: Set alarm alert duration (e.g., `D60`).
- `R<minutes>`: Set re-reminder interval (e.g., `R15`).

### Notifications
- `ALARM_START`: Initial medication alert.
- `ALARM_RE_REMINDER`: Re-triggered alert after missed intake.
- `INTAKE_CONFIRMED`: Intake detected (Reed open + Touch).
- `INTAKE_SUCCESS`: Final intake confirmation and log.
- `ALARM_TIMEOUT`: Alert ended without intake detection.
- `REED_OPEN` / `REED_CLOSED`: Real-time reed switch status.
- `ENTERING_SLEEP`: Device going to deep sleep.

## Hardware Configuration
- **Reed Switch**: GPIO 13 (Input Pull-up)
- **Touch Sensor**: GPIO 4
- **Piezo Buzzer**: GPIO 14
- **Internal LED**: GPIO 2
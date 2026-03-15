# ePO: Technical Blueprint

## Technical Architecture Overview

ePO is built on a local-first, event-driven architecture that bridges hardware and software through BLE. All data lives on-device — no backend, no cloud, no account required. The primary components are:

*   **ESP32 Hardware:** Battery-powered microcontroller managing physical intake sensing and local alerts.
*   **Flutter Mobile App:** Cross-platform application for user-facing schedule management and dose tracking, with all data persisted locally on the device.

### Tech Stack

| Component | Technology |
| :--- | :--- |
| **Microcontroller** | ESP32 (Arduino Framework) |
| **Mobile App** | Flutter (iOS & Android) |
| **Local Storage** | SharedPreferences (settings & medication data) |
| **Notifications** | flutter_local_notifications (on-device scheduling) |
*   **Local Connectivity:** BLE (Bluetooth Low Energy) for pairing, real-time sync, and intake logging.
*   **Remote Sync:** Not in scope — ePO is intentionally offline-first.

---

## Data Model (Local Storage)

All data is stored on-device using `shared_preferences`. The structure maps directly to JSON-serializable Dart models.

### Entities

#### `Medication`
*   `id`: (string) Unique identifier (timestamp-based)
*   `name`: (string) Name of the drug
*   `dosage`: (string) Amount per intake (e.g., "10mg")
*   `stock_count`: (int) Number of pills currently in the box
*   `schedule_hours`: (List<int>) Hours of day for scheduled doses (0–23)
*   `schedule_minutes`: (List<int>) Corresponding minutes for each dose (0–59)

#### `Settings`
*   `alarm_hour`: (int) Hour of the primary alarm
*   `alarm_minute`: (int) Minute of the primary alarm
*   `duration`: (int) Alarm alert duration in seconds
*   `interval`: (int) Reminder re-notification interval in minutes

#### `UsageLog`
*   `id`: (string) Unique log ID
*   `medication_id`: (string) Reference to the medication
*   `status`: (string) "taken", "skipped", or "missed"
*   `timestamp`: (int) Unix timestamp of intake
*   `is_hardware_confirmed`: (bool) True if intake was sensed by the ESP32 via BLE

---

## Hardware Interface

For the prototype, the ESP32 communicates with the Flutter app exclusively via BLE:

1.  **Initial Pairing:** Done via BLE scan.
2.  **State Sync (ESP32 → App → Local Storage):** When a physical intake event occurs (Reed switch + Touch), the ESP32 sends a BLE notification to the App. The App logs this event locally.
3.  **Real-Time Alerts:** The ESP32 manages its own local alarm schedule (synced from the App via BLE) and triggers alerts accordingly.

---

## Logic Flow: The 'Happy Path'

1.  **Schedule Trigger:** A local hardware timer on the ESP32 identifies that a dose is due.
2.  **Hardware Alert:** The ESP32 triggers a buzzer sound and LED blink.
3.  **Local Notification:** The App fires a local mobile notification via `flutter_local_notifications`.
4.  **User Opens Box:** The user physically interacts with the ePO pillbox.
5.  **Intake Verification:** Sensors (Reed switch open + Touch activated) confirm the intake.
6.  **App Updates Local Storage:** The App receives the BLE confirmation, writes the event to `usage_logs` in SharedPreferences, and decrements `stock_count`.
7.  **Success State:** The hardware alert stops, and the App UI reflects the updated status.

---

## Prototype Roadmap (Missing Pieces)

### Firmware
*   [ ] **Sensor Fusion:** Require both Reed Switch and Touch for intake confirmation.
*   [ ] **Alert Timings:** Implement configurable Alarm Duration (auto-snooze) and Reminder Intervals.
*   [ ] **Persistence:** Store duration and interval settings in NVS.

### Flutter App
*   [ ] **Schedule Dashboard:** Implement a daily/weekly timeline UI.
*   [ ] **Stock Logic:** Implement client-side stock decrement and low-stock warnings.
*   [ ] **Medication CRUD:** UI to manage medication details and schedules.
*   [ ] **Local Notifications:** Schedule dose reminders via `flutter_local_notifications`.
*   [ ] **Usage Log Persistence:** Write intake events to local storage (SharedPreferences or SQLite for larger datasets).

---
*This document serves as the technical source of truth for the ePO project. Any changes to the architecture or data model must be reflected here first.*

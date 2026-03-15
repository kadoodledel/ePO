# ePO: Technical Blueprint

## Technical Architecture Overview

ePO is built on a modern, event-driven architecture that bridges hardware and software through a cloud-based real-time database. The primary components are:

*   **ESP32 Hardware:** Battery-powered microcontroller managing physical intake sensing and local alerts.
*   **Flutter Mobile App:** Cross-platform application for user-facing schedule management and dose tracking.
*   **Google Firebase Ecosystem:** Backend for authentication, real-time data synchronization, and cloud logic.

### Tech Stack

| Component | Technology |
| :--- | :--- |
| **Microcontroller** | ESP32 (Arduino Framework) |
| **Mobile App** | Flutter (iOS & Android) |
| **Backend** | Firebase (Auth, Firestore, Cloud Functions, Messaging) |
*   **Local Connectivity:** BLE (Bluetooth Low Energy) for initial setup, local sync, and real-time intake logging (Prototype Focus).
*   **Remote Sync:** Wi-Fi (Future phase; currently not in scope for the prototype).

---

## Data Model (Cloud Firestore)

A scalable, hierarchical Firestore schema is used to manage multi-user and multi-medication data.

### Collections

#### `users`
*   `uid`: (string) Unique Firebase UID
*   `email`: (string) User email
*   `pillbox_id`: (string) Identifier for the paired ESP32 device
*   `settings`: (map) User preferences for notifications

#### `medications`
*   `id`: (string) Unique medication ID
*   `user_id`: (string) Reference to the owning user
*   `name`: (string) Name of the drug
*   `dosage`: (string) Amount per intake (e.g., "10mg")
*   `stock_count`: (int) Number of pills currently in the box
*   `total_supply`: (int) Total number of pills on hand
*   `low_stock_threshold`: (int) Count at which to trigger a reminder

#### `schedules`
*   `id`: (string) Unique schedule ID
*   `medication_id`: (string) Reference to the medication
*   `user_id`: (string) Reference to the user
*   `scheduled_time`: (timestamp) Time for the next dose
*   `frequency`: (string) E.g., "daily", "weekly"
*   `is_active`: (bool) Toggle for enabling/disabling the schedule

#### `usage_logs`
*   `id`: (string) Unique log ID
*   `user_id`: (string) Reference to the user
*   `medication_id`: (string) Reference to the medication
*   `status`: (string) "taken", "skipped", "missed"
*   `timestamp`: (timestamp) Actual time of intake
*   `is_hardware_confirmed`: (bool) True if intake was sensed by the ESP32

---

## Hardware Interface

For the prototype, the ESP32 communicates with the Flutter app exclusively via BLE:

1.  **Initial Pairing:** Done via BLE.
2.  **State Sync (ESP32 to App to Cloud):** When a physical intake event occurs (Reed switch + Touch), the ESP32 sends a notification to the App via BLE. The App then logs this event to Firestore.
3.  **Real-Time Alerts:** The ESP32 manages its own local alarm schedule (synced from the App via BLE) and triggers alerts accordingly.

---

## Logic Flow: The 'Happy Path'

1.  **Schedule Trigger:** A local hardware timer on the ESP32 identifies that a dose is due.
2.  **Hardware Alert:** The ESP32 triggers a buzzer sound and LED blink.
3.  **Push Notification:** The App (if connected) or local mobile notifications alert the user.
4.  **User Opens Box:** The user physically interacts with the ePO pillbox.
5.  **Intake Verification:** Sensors (Reed switch open + Touch activated) confirm the intake.
6.  **App Updates Firestore:** The App receives the confirmation via BLE, logs it in `usage_logs`, and decrements the `stock_count`.
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

---
*This document serves as the technical source of truth for the ePO project. Any changes to the architecture or data model must be reflected here first.*

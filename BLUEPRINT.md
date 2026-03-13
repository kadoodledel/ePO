# Clara: Technical Blueprint

## Technical Architecture Overview

Clara is built on a modern, event-driven architecture that bridges hardware and software through a cloud-based real-time database. The primary components are:

*   **ESP32 Hardware:** Battery-powered microcontroller managing physical intake sensing and local alerts.
*   **Flutter Mobile App:** Cross-platform application for user-facing schedule management and dose tracking.
*   **Google Firebase Ecosystem:** Backend for authentication, real-time data synchronization, and cloud logic.

### Tech Stack

| Component | Technology |
| :--- | :--- |
| **Microcontroller** | ESP32 (Arduino Framework) |
| **Mobile App** | Flutter (iOS & Android) |
| **Backend** | Firebase (Auth, Firestore, Cloud Functions, Messaging) |
| **Local Connectivity** | BLE (Bluetooth Low Energy) for initial setup and local sync |
| **Remote Sync** | Wi-Fi (HTTPS / Firestore REST API) |

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

The ESP32 communicates with the Firebase backend using a hybrid approach:

1.  **Initial Pairing & Wi-Fi Provisioning:** Done via BLE using a secure Flutter-to-ESP32 handshake.
2.  **State Sync (ESP32 to Cloud):** The ESP32 sends a POST request to a Firebase Cloud Function (or uses the Firestore REST API directly) when a physical intake event occurs (e.g., Reed switch open + Touch sensor active).
3.  **Real-Time Alerts (Cloud to ESP32):** While primarily sleeping to save battery, the ESP32 wakes up periodically or can be woken by a hardware timer based on its local schedule (synced once daily from Firestore).

---

## Logic Flow: The 'Happy Path'

1.  **Schedule Trigger:** A Firebase Cloud Function or a local hardware timer on the ESP32 identifies that a dose is due.
2.  **Push Notification:** Firebase Cloud Messaging sends a push notification to the Flutter app.
3.  **Hardware Alert:** The ESP32 triggers a buzzer sound and LED blink to alert the user locally.
4.  **User Opens Box:** The user physically interacts with the Clara pillbox.
5.  **ESP32 Updates Firestore:** Sensors (Reed switch + Touch) confirm the intake. The ESP32 sends a signal to the `usage_logs` collection.
6.  **App Confirms Intake:** The Flutter app, listening to Firestore changes, updates the UI in real-time, marks the dose as 'taken', and decrements the `stock_count` in the `medications` collection.
7.  **Success State:** A success message or animation appears on the phone, and the hardware alert stops.

---
*This document serves as the technical source of truth for the Clara project. Any changes to the architecture or data model must be reflected here first.*

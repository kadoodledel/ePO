# ePO Smart Pill Box - Mobile App

This is the Flutter companion app for the ePO Smart Pill Box.

## Features

- **BLE Communication**: Connect to the ESP32-based Pill Box.
- **Time Synchronization**: Automatically syncs the device time upon connection.
- **Medication Management**: Configure alarm times, durations, and reminder intervals.
- **Intake Logging**: Records medication intake events locally for the prototype.

## Setup Instructions

### 1. Flutter Dependencies

Run the following command to install dependencies:

```bash
flutter pub get
```

### 2. Permissions

#### Android
Ensure the following permissions are handled in `AndroidManifest.xml` (already configured for basic BLE):
- `BLUETOOTH_SCAN`
- `BLUETOOTH_CONNECT`
- `ACCESS_FINE_LOCATION`

#### iOS
Ensure the following keys are in `Info.plist`:
- `NSBluetoothAlwaysUsageDescription`
- `NSBluetoothPeripheralUsageDescription`

## Architecture

The app follows a Clean Architecture approach:

- **Data Layer (`lib/data`)**: Contains `BLEService` for low-level Bluetooth communication.
- **Repository Layer (`lib/repository`)**: `MedicationRepository` handles local data management.
- **UI Layer (`lib/ui`)**:
  - `AppState`: Manages global state and coordinates between BLE and Repositories.
  - `Screens`: `DashboardScreen`, `SettingsScreen`.

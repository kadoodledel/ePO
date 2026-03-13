# ePO Smart Pill Box - Mobile App

This is the Flutter companion app for the ePO Smart Pill Box.

## Features

- **Firebase Authentication**: Secure user login.
- **BLE Communication**: Connect to the ESP32-based Pill Box.
- **Time Synchronization**: Automatically syncs the device time upon connection.
- **Medication Management**: Configure alarm times, durations, and reminder intervals.
- **Intake Logging**: Automatically logs medication intake to Firestore.

## Setup Instructions

### 1. Firebase Configuration

To get the app running with Firebase, you need to add your platform-specific configuration files:

#### Android
1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Add an Android app with the package name `com.example.epo_app` (or your chosen package name).
3. Download `google-services.json` and place it in `app/android/app/`.

#### iOS
1. Add an iOS app to your Firebase project.
2. Download `GoogleService-Info.plist` and place it in `app/ios/Runner/`.
3. Open the project in Xcode and ensure the file is included in the project.

### 2. Flutter Dependencies

Run the following command to install dependencies:

```bash
flutter pub get
```

### 3. Permissions

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
- **Repository Layer (`lib/repository`)**: `MedicationRepository` handles Firestore data syncing.
- **UI Layer (`lib/ui`)**:
  - `AppState`: Manages global state and coordinates between BLE and Repositories.
  - `Screens`: `LoginScreen`, `DashboardScreen`, `SettingsScreen`.

/**
 * @file ePO.ino
 * @brief Main entry point for the ePO Smart Pill Box firmware.
 * @author Jules
 */

#include "src/EpoController.h"

EpoController controller;

/**
 * @brief Arduino setup function.
 */
void setup() {
  // Use serial for debugging if needed (optional for production)
  Serial.begin(115200);
  Serial.println("ePO Smart Pill Box starting...");

  // Initialize the controller and its modules
  controller.begin();

  Serial.println("System initialized. Waiting for BLE connection...");
}

/**
 * @brief Arduino main loop.
 */
void loop() {
  // The controller handles non-blocking updates for all modules
  controller.update();

  // Minimal delay to prevent watchdog issues and save a tiny bit of power
  // without affecting responsiveness.
  // In a real deep-sleep scenario, this loop would be replaced by light-sleep.
  delay(10);
}

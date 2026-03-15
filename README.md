# ePO: Smart Pillbox for Medication Adherence

## Project Vision & Scope

Project ePO is designed to bridge the gap in medication adherence for young adults (18-40) living with chronic conditions such as ADHD, Depression, Epilepsy, and Parkinson’s. By combining a portable, hardware-enabled pillbox with a seamless mobile experience, ePO ensures that managing complex medication schedules is intuitive rather than a burden.

### The Problem
Traditional pillboxes are often bulky, clinical, and disconnected from the digital lives of young adults. For patients with conditions like ADHD or Depression, consistency is key, yet forgetfulness or lack of motivation can lead to missed doses, significantly impacting their quality of life. Current solutions lack the sophisticated notification systems and stock tracking required for modern chronic disease management.

### The Solution: ePO
ePO is a battery-powered, portable smart pillbox (built on the ESP32 platform) that syncs in real-time with a Flutter-based mobile application. It acts as a physical extension of the user’s digital health routine, providing both tactile and digital feedback to ensure medication is taken on time, every time.

### Core Features

#### 1. Intuitive Schedules
A medication logging flow inspired by industry leaders like Apple Medication Reminders and MyTherapy.
*   **Easy Setup:** Quickly add medications with dosage instructions.
*   **Visual Timeline:** A clear daily view of upcoming and completed doses.
*   **Flexible Scheduling:** Support for daily, weekly, or specific interval dosing.

#### 2. Advanced Stock Management
ePO doesn’t just remind you to take your pills; it knows when you’re running low.
*   **Pill Counting:** Tracks the number of pills remaining in the physical box vs. the total supply.
*   **Low Stock Alerts:** Customizable thresholds (e.g., "Remind me when I have 5 days left") to ensure refills are ordered on time.

#### 3. Sophisticated Notifications
Configurable alerts designed to be persistent yet non-intrusive.
*   **Local Notifications:** Timely on-device alerts via the system notification scheduler.
*   **Hardware Alerts:** Alarm-like sounds and LED indicators on the ePO pillbox itself.
*   **Delayed Reminders:** Intelligent re-notifications for missed doses to prevent "notification fatigue" while ensuring compliance.

---
*This document serves as the primary vision for the ePO project. For technical implementation details, please refer to [BLUEPRINT.md](BLUEPRINT.md).*

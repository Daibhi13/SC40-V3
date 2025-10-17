
# 🏃‍♂️ Accelerate Your Speed – Apple Watch Ultra 2

A comprehensive sprint tracking app that combines **iPhone GPS tracking** with **Apple Watch Ultra 2** health and performance metrics for elite-level sprint analysis.

This app is for anyone who wants to get faster, fitter, and stronger. Designed for athletes and people looking for an alternative to jogging, it focuses on improving 40-yard dash times to enhance athletic performance and increase chances of being selected for competitive sports. Inspired by the Combine 44, this app is tailored for release in the **US**, **Canada**, and the **UK**.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Current Status](#current-status)
- [Prerequisites](#prerequisites)
- [Frameworks & Permissions](#frameworks--permissions)
- [Setup Instructions](#setup-instructions)
  - [1. Add Watch App Target in Xcode](#1-add-watch-app-target-in-xcode)
  - [2. Replace Generated Files](#2-replace-generated-files)
  - [3. Add WatchConnectivity Framework](#3-add-watchconnectivity-framework)
  - [4. Build and Deploy](#4-build-and-deploy)
- [Testing Connectivity](#testing-connectivity)
- [Troubleshooting](#troubleshooting)
- [Developer Automation Tools](#developer-automation-tools)
- [File Structure](#file-structure)
- [Next Steps](#next-steps)

---

**Accelerate Your Speed** is for anyone who wants to get faster, fitter, and stronger.

Designed for athletes and individuals looking for an alternative to jogging, this app also helps improve your 40-yard dash time or 100m dash — giving you a competitive edge to get noticed and picked for sports. Whether you're training for performance, speed, or Combine 44 trials, this app will help unlock your sprinting potential.

**Accelerate Your Speed** is a 12-week sprint program structured around onboarding input — including user level (Beginner, Intermediate, Advanced) and weekly training frequency.

🎯 Initial release targets: **US**, **Canada**, and **UK**.


## 🧠 Overview

A dual-device workout platform with:
- Real-time sprint tracking
- Heart rate monitoring
- Live metrics dashboard
- HealthKit + CoreLocation + WatchConnectivity support

---

## ✅ Features

### 📱 iPhone App:
- Real-time Apple Watch connection status
- Sprint controls: Start / Stop / Pause
- Live performance metrics (pace, GPS)
- Debug info panel for WatchConnectivity
- Health data visualization
- Two-way messaging system with Apple Watch

### ⌚ Apple Watch Ultra 2 App:
- Full HealthKit workout session tracking
- Heart rate & calorie metrics
- Three-tab UI: Sprint | Health | Messaging
- Send/receive messages with iPhone
- Background workout processing
- Auto-sync of workout data

---

## 🚦 Current Status

| Component | Status |
|----------|--------|
| iOS App | ✅ Fully functional |
| watchOS App | ✅ Files complete |
| Watch Target | ⚠️ Must be added in Xcode |
| Frameworks | ✅ Integrated |

---

## 🛠️ Prerequisites

- Xcode 15+
- iOS 17.0+ and watchOS 10.0+
- Apple Watch Ultra 2 (paired)
- Enable **Health** and **Location** permissions
- Ensure both devices are on the same WiFi network

---

## 📦 Frameworks & Permissions

### iOS Target:
- `WatchConnectivity.framework`
- `HealthKit.framework`
- `CoreLocation.framework`

### watchOS Target:
- `WatchConnectivity.framework`
- `HealthKit.framework`
- `WorkoutKit.framework`

### Permissions Required:
```plist
NSHealthShareUsageDescription
NSLocationWhenInUseUsageDescription
NSLocationAlwaysAndWhenInUseUsageDescription
```

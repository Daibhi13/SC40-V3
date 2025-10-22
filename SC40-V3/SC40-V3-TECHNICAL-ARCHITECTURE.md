# SC40 Sprint Coach - Technical Architecture & Flow Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Data Architecture](#data-architecture)
3. [UI Flow Architecture](#ui-flow-architecture)
4. [Cross-Device Synchronization](#cross-device-synchronization)
5. [Apple Watch Integration](#apple-watch-integration)
6. [Premium Features Architecture](#premium-features-architecture)
7. [Performance & Optimization](#performance--optimization)
8. [Technical Implementation Details](#technical-implementation-details)

---

## System Overview

### Application Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    SC40 Sprint Coach                        │
├─────────────────────┬───────────────────────────────────────┤
│     iPhone App      │           Apple Watch App             │
├─────────────────────┼───────────────────────────────────────┤
│ • 12-Week Program   │ • Session Cards Interface            │
│ • Sprint Timer Pro  │ • Sprint Timer Pro Watch             │
│ • Time Trial        │ • Multi-View Workout Interface       │
│ • User Onboarding   │ • Real-Time Analytics                │
│ • Analytics         │ • Cross-Device Sync                  │
└─────────────────────┴───────────────────────────────────────┘
```

### Core Technologies
- **Framework**: SwiftUI + UIKit (iOS 17.0+, watchOS 10.0+)
- **Data Persistence**: Core Data + UserDefaults
- **Cross-Device Communication**: WatchConnectivity Framework
- **Location Services**: CoreLocation + GPS tracking
- **Health Integration**: HealthKit + WorkoutKit
- **Audio/Haptics**: AVFoundation + WKInterfaceDevice

---

## Data Architecture

### 1. Core Data Models

#### TrainingSession Model
```swift
struct TrainingSession: Codable, Identifiable, Sendable {
    let id: UUID
    let week: Int
    let day: Int
    let type: String // "Acceleration", "Max Velocity", etc.
    let focus: String // "Block Starts", "Top Speed Mechanics"
    let sprints: [SprintSet]
    let accessoryWork: [String]
    let notes: String?
    
    // Session Results
    var isCompleted: Bool = false
    var completionDate: Date?
    var sprintTimes: [Double] = []
    var averageTime: Double?
    var bestTime: Double?
}
```

#### SprintSet Model
```swift
struct SprintSet: Codable, Sendable {
    let distanceYards: Int
    let reps: Int
    let intensity: String // "max", "submax", "moderate", "easy", "test"
}
```

#### RepData Model
```swift
struct RepData: Codable, Identifiable {
    let id: UUID
    let repNumber: Int
    let distance: Int
    let time: Double?
    let speed: Double?
    let timestamp: Date
    let gpsData: GPSData?
}
```

### 2. Data Flow Architecture

#### Session Data Flow
```
User Selection → Session Loading → Workout Execution → Data Collection → Persistence
     ↓                ↓                  ↓                 ↓              ↓
Select Session → Load SprintSets → Execute Workout → Collect Times → Save Results
     ↓                ↓                  ↓                 ↓              ↓
UI Update → ViewModel Update → State Management → Analytics → Cross-Device Sync
```

#### Data Persistence Strategy
```
┌─────────────────────────────────────────────────────────────┐
│                    Data Persistence Layers                 │
├─────────────────────┬───────────────────────────────────────┤
│    Temporary        │           Permanent                   │
├─────────────────────┼───────────────────────────────────────┤
│ • @State variables  │ • Core Data (session history)        │
│ • @Published props  │ • UserDefaults (preferences)         │
│ • ViewModel state   │ • Keychain (authentication)          │
│ • Session cache     │ • HealthKit (workout data)           │
└─────────────────────┴───────────────────────────────────────┘
```

### 3. Data Synchronization Patterns

#### iPhone ↔ Watch Sync
```swift
// Data Sync Flow
iPhone App → WatchConnectivityManager → WatchConnectivity Framework → Watch App
    ↓                    ↓                        ↓                      ↓
Send Sessions → Encode Data → Transfer Message → Receive & Decode → Update UI
    ↓                    ↓                        ↓                      ↓
Update State → Confirm Sync → Handle Response → Validate Data → Persist Locally
```

#### Emergency Fallback System
```
┌─────────────────────────────────────────────────────────────┐
│              Zero Buffering Architecture                    │
├─────────────────────┬───────────────────────────────────────┤
│   Primary Source    │           Fallback Source             │
├─────────────────────┼───────────────────────────────────────┤
│ iPhone Sync Data    │ Emergency Session Library             │
│ Real-time Updates   │ Hardcoded Session Templates          │
│ Full 12-week Plan   │ Representative Workouts               │
│ User Customization  │ Offline Functionality                │
└─────────────────────┴───────────────────────────────────────┘
```

---

## UI Flow Architecture

### 1. iPhone App UI Flow

#### Main Navigation Flow
```
App Launch → EntryIOSView → Navigation Decision
     ↓              ↓              ↓
Check Auth → Onboarding/Login → TrainingView (Main Interface)
     ↓              ↓              ↓
Validate → Setup Profile → Session Selection → Workout Execution
```

#### TrainingView Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                      TrainingView                           │
├─────────────────────┬───────────────────────────────────────┤
│   Session Cards     │           Action Buttons             │
├─────────────────────┼───────────────────────────────────────┤
│ • Progress Card     │ • Start Workout                      │
│ • Training Sessions │ • Sprint Timer Pro                   │
│ • Time Trial        │ • Settings Menu                      │
│ • Custom Workouts   │ • Sync with Watch                    │
└─────────────────────┴───────────────────────────────────────┘
```

#### Workout Execution Flow
```
Session Selection → MainProgramWorkoutView → 7-Stage Workflow
       ↓                     ↓                      ↓
Load Session → Initialize ViewModel → Execute Phases
       ↓                     ↓                      ↓
Configure UI → Start Workout → Warmup → Drills → Strides → Sprints → Rest → Cooldown → Complete
```

### 2. Apple Watch UI Flow

#### Watch App Entry Flow
```
App Launch → EntryViewWatch → Connection Check → Navigation Decision
     ↓              ↓               ↓                ↓
Splash Screen → iPhone Sync → Session Availability → Main Interface
     ↓              ↓               ↓                ↓
Quick Exit → Sync Status → Emergency Fallback → DaySessionCardsWatchView
```

#### Session Cards Interface
```
┌─────────────────────────────────────────────────────────────┐
│                 DaySessionCardsWatchView                    │
├─────────────────────┬───────────────────────────────────────┤
│   Session Carousel  │           Premium Features            │
├─────────────────────┼───────────────────────────────────────┤
│ • Progress Card     │ • Time Trial (Card 4)               │
│ • Training Sessions │ • Sprint Timer Pro (Card 5)         │
│ • Swipe Navigation  │ • Custom Configurations             │
│ • Digital Crown     │ • Cross-Device Sync                 │
└─────────────────────┴───────────────────────────────────────┘
```

#### Multi-View Workout Interface
```
    ⚙️ ControlWatchView (Settings, Pause, Phase Control)
         ↑
🎵 MusicWatchView ← 🏃‍♂️ MainWorkoutWatchView → 📊 RepLogWatchLiveView
         ↓
    Swipe Navigation System
```

### 3. Sprint Timer Pro UI Flow

#### Configuration Flow
```
Sprint Timer Pro Card → SprintTimerProWatchView → Configuration Interface
         ↓                      ↓                        ↓
Tap to Open → 3-Column Pickers → Distance/Reps/Rest Selection
         ↓                      ↓                        ↓
Preview Workout → Estimated Duration → Start Custom Workout
```

#### Picker Interface Design
```
┌─────────────────────────────────────────────────────────────┐
│              Sprint Timer Pro Configuration                 │
├─────────────────────┬─────────────────┬───────────────────┤
│      DISTANCE       │      REPS       │      REST         │
├─────────────────────┼─────────────────┼───────────────────┤
│   20-100 yards      │     1-8 reps    │    1-5 minutes    │
│   Wheel Picker      │   Wheel Picker  │   Wheel Picker    │
│   Optimized Range   │  Watch-Friendly │  Practical Times  │
└─────────────────────┴─────────────────┴───────────────────┘
```

---

## Cross-Device Synchronization

### 1. WatchConnectivity Architecture

#### Communication Patterns
```swift
// Bidirectional Communication
iPhone ←→ WatchConnectivityManager ←→ Apple Watch
   ↓              ↓                      ↓
Send Sessions → Encode/Transfer → Receive/Decode
   ↓              ↓                      ↓
Update State → Handle Response → Update UI
```

#### Message Types
```swift
enum WatchMessage {
    case sessionSync([TrainingSession])
    case workoutStart(TrainingSession)
    case workoutComplete(WorkoutResults)
    case customWorkout(SprintTimerProConfig)
    case emergencySync
}
```

### 2. Sync Strategies

#### Aggressive Sync System
```
┌─────────────────────────────────────────────────────────────┐
│                    Sync Trigger Points                      │
├─────────────────────┬───────────────────────────────────────┤
│    Automatic        │           Manual                      │
├─────────────────────┼───────────────────────────────────────┤
│ • App Launch        │ • Double-tap gesture                 │
│ • Session Change    │ • Settings sync button               │
│ • Workout Complete  │ • Emergency fallback detection       │
│ • Background Refresh│ • User-initiated force sync          │
└─────────────────────┴───────────────────────────────────────┘
```

#### Data Validation & Error Handling
```swift
// Sync Validation Flow
Receive Data → Validate Format → Check Integrity → Apply Updates → Confirm Success
     ↓              ↓               ↓                ↓              ↓
JSON Decode → Schema Check → Data Consistency → UI Update → Send Confirmation
     ↓              ↓               ↓                ↓              ↓
Error Handle → Retry Logic → Fallback Mode → User Notification → Log Event
```

---

## Apple Watch Integration

### 1. Adaptive Sizing System

#### WatchAdaptiveSizing Architecture
```swift
struct WatchAdaptiveSizing {
    // Device Detection
    static var isUltra: Bool { screenSize.width >= 410 }
    static var isLarge: Bool { screenSize.width >= 368 && screenSize.width < 410 }
    static var isStandard: Bool { screenSize.width < 368 }
    
    // Responsive Properties
    static var spacing: CGFloat { isUltra ? 10 : isLarge ? 8 : 6 }
    static var padding: CGFloat { isUltra ? 12 : isLarge ? 10 : 8 }
    static var buttonHeight: CGFloat { isUltra ? 50 : isLarge ? 46 : 42 }
}
```

#### Responsive Design Matrix
```
┌─────────────────────────────────────────────────────────────┐
│                 Apple Watch Size Matrix                     │
├─────────────────────┬─────────────────┬───────────────────┤
│   Apple Watch SE    │  Apple Watch 9  │ Apple Watch Ultra │
│     (40/44mm)       │    (41/45mm)    │     (49mm)        │
├─────────────────────┼─────────────────┼───────────────────┤
│ Spacing: 6px        │ Spacing: 8px    │ Spacing: 10px     │
│ Padding: 8px        │ Padding: 10px   │ Padding: 12px     │
│ Button: 42px        │ Button: 46px    │ Button: 50px      │
│ Font: 14px          │ Font: 15px      │ Font: 16px        │
└─────────────────────┴─────────────────┴───────────────────┘
```

### 2. Workout Execution Architecture

#### WorkoutWatchViewModel Flow
```swift
// Workout State Management
Initialize → Configure → Start → Execute → Complete → Sync
    ↓           ↓         ↓       ↓         ↓         ↓
Load Data → Set Params → Begin → Track → Finish → Upload
    ↓           ↓         ↓       ↓         ↓         ↓
UI Setup → Timer Start → GPS → Analytics → Results → iPhone
```

#### Multi-Phase Workout System
```
┌─────────────────────────────────────────────────────────────┐
│                7-Stage Workout Architecture                 │
├─────────────────────┬───────────────────────────────────────┤
│      Phases         │           Implementation             │
├─────────────────────┼───────────────────────────────────────┤
│ 1. Warmup           │ WarmupWatchView + Timer               │
│ 2. Drills           │ DrillWatchView + Instructions         │
│ 3. Strides          │ SprintPhaseWatchView + GPS            │
│ 4. Sprints          │ MainWorkoutWatchView + Analytics      │
│ 5. Rest             │ RestWatchView + Recovery Timer        │
│ 6. Cooldown         │ CooldownWatchView + Guidance          │
│ 7. Complete         │ SummaryReportView + Data Sync         │
└─────────────────────┴───────────────────────────────────────┘
```

---

## Premium Features Architecture

### 1. Sprint Timer Pro Implementation

#### Component Architecture
```
SprintTimerProWatchView
├── Configuration Interface
│   ├── Distance Picker (20-100 yards)
│   ├── Reps Picker (1-8 reps)
│   └── Rest Picker (1-5 minutes)
├── Workout Preview
│   ├── Parameter Summary
│   ├── Estimated Duration
│   └── Start Button
└── Integration Layer
    ├── TrainingSession Creation
    ├── WorkoutWatchViewModel Setup
    └── Cross-Device Sync
```

#### Custom Workout Flow
```
Configuration → Session Creation → ViewModel Setup → Workout Execution
      ↓               ↓                ↓                 ↓
User Picks → TrainingSession → WorkoutWatchViewModel → MainWorkoutWatchView
      ↓               ↓                ↓                 ↓
Validate → Custom SprintSet → Initialize Timers → Execute 7-Stage Flow
```

### 2. Time Trial Architecture

#### Performance Testing System
```
┌─────────────────────────────────────────────────────────────┐
│                Time Trial Implementation                    │
├─────────────────────┬───────────────────────────────────────┤
│    Data Collection  │           Analysis                    │
├─────────────────────┼───────────────────────────────────────┤
│ • GPS Tracking      │ • Speed Calculations                 │
│ • Precise Timing    │ • Performance Metrics               │
│ • Location Data     │ • Historical Comparison              │
│ • Heart Rate        │ • Progress Tracking                  │
└─────────────────────┴───────────────────────────────────────┘
```

### 3. 12-Week Program Architecture

#### Program Structure
```swift
// Program Hierarchy
12-Week Program
├── Phase 1: Foundation (Weeks 1-4)
│   ├── Acceleration Focus
│   ├── Basic Speed Development
│   └── Movement Mechanics
├── Phase 2: Development (Weeks 5-8)
│   ├── Max Velocity Training
│   ├── Speed Endurance
│   └── Advanced Techniques
└── Phase 3: Peak Performance (Weeks 9-12)
    ├── Competition Preparation
    ├── Performance Testing
    └── Maintenance Protocols
```

---

## Performance & Optimization

### 1. Memory Management

#### State Management Strategy
```swift
// Efficient State Architecture
@StateObject → Single Source of Truth
@ObservedObject → Shared ViewModels
@Published → Reactive Updates
@State → Local UI State
```

#### Data Loading Optimization
```
Lazy Loading → On-Demand Fetch → Cache Strategy → Memory Cleanup
     ↓              ↓                ↓              ↓
Load Visible → Fetch When Needed → Store Results → Release Unused
```

### 2. Battery Optimization

#### Power Management
```
┌─────────────────────────────────────────────────────────────┐
│                Battery Optimization Strategy                │
├─────────────────────┬───────────────────────────────────────┤
│   High Power Mode   │           Low Power Mode              │
├─────────────────────┼───────────────────────────────────────┤
│ • Continuous GPS    │ • Reduced GPS frequency               │
│ • Real-time Analytics│ • Batch processing                   │
│ • Live Sync         │ • Deferred sync                      │
│ • Full UI Updates   │ • Essential updates only             │
└─────────────────────┴───────────────────────────────────────┘
```

### 3. Network Optimization

#### Sync Efficiency
```swift
// Smart Sync Strategy
Delta Updates → Compression → Batch Transfer → Validation
     ↓              ↓            ↓               ↓
Only Changes → Reduce Size → Single Message → Verify Integrity
```

---

## Technical Implementation Details

### 1. Error Handling Architecture

#### Comprehensive Error Management
```swift
enum SC40Error: Error {
    case syncFailure(String)
    case dataCorruption(String)
    case networkUnavailable
    case authenticationRequired
    case workoutInProgress
    case gpsUnavailable
}

// Error Recovery Flow
Error Detected → Log Event → User Notification → Recovery Action → Fallback Mode
```

### 2. Testing Architecture

#### Test Coverage Strategy
```
┌─────────────────────────────────────────────────────────────┐
│                    Testing Pyramid                         │
├─────────────────────┬───────────────────────────────────────┤
│    Unit Tests       │           Integration Tests           │
├─────────────────────┼───────────────────────────────────────┤
│ • ViewModels        │ • Cross-Device Sync                  │
│ • Data Models       │ • Workout Flow                       │
│ • Utility Functions │ • UI Navigation                      │
│ • Business Logic    │ • Data Persistence                   │
└─────────────────────┴───────────────────────────────────────┘
```

### 3. Security Architecture

#### Data Protection Strategy
```
┌─────────────────────────────────────────────────────────────┐
│                   Security Implementation                   │
├─────────────────────┬───────────────────────────────────────┤
│   Data at Rest      │           Data in Transit             │
├─────────────────────┼───────────────────────────────────────┤
│ • Keychain Storage  │ • WatchConnectivity Encryption       │
│ • Core Data         │ • HTTPS Communication                │
│ • Secure Enclave    │ • Certificate Pinning                │
│ • Biometric Auth    │ • Message Validation                 │
└─────────────────────┴───────────────────────────────────────┘
```

---

## Conclusion

The SC40 Sprint Coach application represents a comprehensive, professional-grade fitness platform with:

- **Robust Architecture**: Scalable, maintainable codebase
- **Cross-Device Excellence**: Seamless iPhone ↔ Apple Watch integration
- **Premium Features**: Sprint Timer Pro, Time Trial, 12-Week Program
- **Performance Optimized**: Battery-efficient, responsive UI
- **Production Ready**: Error handling, testing, security

This technical architecture ensures a world-class user experience while maintaining code quality and system reliability.

---

*Last Updated: October 21, 2025*
*Version: 3.0 - Sprint Timer Pro Implementation Complete*

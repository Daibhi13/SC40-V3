# SC40-V6: Sprint Coach 40

A comprehensive iOS and watchOS sprint training application with AI-powered adaptive programming, real-time GPS tracking, Apple Watch integration, and professional analytics.

## Overview

SC40-V6 is a 95% complete MVVM architecture-based app designed for sprint training, focusing on 40-yard dash improvement. It features adaptive programming, pyramid sessions, active recovery, and seamless iPhone-Watch connectivity.

## Features

### Core Functionality
- **Adaptive Programming**: AI adjusts training based on user performance and preferences.
- **Pyramid Sessions**: Up-down pyramids (10-40m) for all levels.
- **Active Recovery**: No-jogging recovery with drills, strides, flexibility.
- **Real-time Tracking**: GPS and HealthKit integration for accurate metrics.
- **Apple Watch Integration**: Full workout sessions on Watch with iPhone sync.

### Training Programs
- **400+ Sessions**: Comprehensive library with pyramid, sprint, recovery sessions.
- **All Levels**: Beginner, Intermediate, Advanced, Elite programs.
- **12-Week Progression**: Structured programs with time trials.

### Technical Stack
- **SwiftUI**: Modern UI framework.
- **Core Data**: Local data persistence.
- **HealthKit**: Workout and health data integration.
- **WatchConnectivity**: iPhone-Watch communication.
- **MVVM Architecture**: Clean, maintainable code structure.

## Project Structure

```
SC40-V6/
├── SC40-V6/                    # Main iOS App
│   ├── Models/                 # Data models and libraries
│   ├── Views/                  # SwiftUI views
│   ├── ViewModels/             # MVVM view models
│   ├── Services/               # Business logic and APIs
│   ├── Utils/                  # Utilities and extensions
│   └── Resources/              # Assets and configurations
├── SC40-V6-Watch App/          # WatchOS App
│   ├── Views Watch/            # Watch-specific views
│   ├── Services Watch/         # Watch services
│   └── Utils Watch/            # Watch utilities
├── SC40-V6.xcodeproj/          # Xcode project file
└── README.md                   # This file
```

## Setup Instructions

### Prerequisites
- Xcode 15+
- iOS 17+ target
- watchOS 10+ for Watch app

### Installation
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd SC40-V6
   ```

2. Open in Xcode:
   ```bash
   open SC40-V6.xcodeproj
   ```

3. Build and run:
   - Select SC40-V6 scheme for iPhone.
   - Select SC40-V6 Watch App for Watch.

### Configuration
- Enable HealthKit in Capabilities.
- Set up code signing for iOS and Watch targets.
- Configure WatchConnectivity for iPhone-Watch sync.

## Usage

1. **Onboarding**: Complete user profile and baseline 40-yard time.
2. **Program Selection**: Choose level and days per week.
3. **Training**: Follow pyramid sessions and active recovery.
4. **Tracking**: View progress in history and stats.
5. **Sync**: Use Watch for workouts, iPhone for analytics.

## Recent Updates

### Pyramid Programs
- Added 100+ pyramid sessions for all levels.
- Up-down pyramids (10-40m increments).
- Active recovery with drills, strides, flexibility.

### Session Library
- Expanded to 400 sessions.
- All levels supported.
- Rest and active recovery included.

### Watch Integration
- Pyramid session as Week 1, Day 1 for all levels.
- Real-time sync with iPhone.

## Development Notes

- **Version Control**: Git repository with feature branches.
- **Testing**: Unit tests for models and view models.
- **Performance**: Optimized for Watch performance.
- **Accessibility**: Full VoiceOver support.

## Contributing

1. Fork the repository.
2. Create a feature branch.
3. Make changes.
4. Submit a pull request.

## License

Proprietary - © 2025 Sprint Coach 40.

## Contact

For support or inquiries, contact the development team.

# Sprint Coach 40 - Project Folder Layout

```
SC40-V3/                                    # Main Project Root
├── SC40-V3/                               # iOS App Target
│   ├── Assets.xcassets/                   # App icons, images, colors
│   ├── Configuration/                     # Configuration files
│   ├── ContentView.swift                  # Main app entry point
│   ├── Info.plist                         # App configuration
│   ├── SC40_V3.entitlements              # App capabilities
│   ├── SC40_V3App.swift                   # App lifecycle
│   ├── SC40_V3_App.swift                  # App delegate
│   │
│   ├── Models/                            # Data Models & Business Logic
│   │   ├── ComprehensiveSessionLibrary.swift
│   │   ├── SessionLibrary.swift          # 84684 bytes - Main session library
│   │   ├── UserProfileViewModel.swift    # 20226 bytes - User management
│   │   ├── AdaptiveSprintProgram.swift
│   │   ├── ProgramScheduler.swift
│   │   ├── TrainingSession.swift
│   │   ├── UserProfile.swift
│   │   └── [35+ other model files]
│   │
│   ├── Services/                          # External Services & APIs
│   │   ├── LocationService.swift
│   │   ├── StoreKitService.swift
│   │   ├── NewsService.swift
│   │   ├── ReferralService.swift
│   │   ├── PlatformWorkoutManager.swift
│   │   └── ErrorHandling.swift
│   │
│   ├── Shared/                            # Shared utilities
│   │   ├── Item.swift
│   │   └── WatchSessionManager.swift     # 49771 bytes - Cross-device sync
│   │
│   ├── UI/                                # User Interface Components
│   │   ├── Components/                    # Reusable UI components
│   │   │   ├── RecordCard.swift
│   │   │   ├── StrideTestingView.swift
│   │   │   └── [6 other components]
│   │   │
│   │   ├── Views/                         # Main view controllers
│   │   │   ├── TrainingView.swift        # 37211 bytes - Main training interface
│   │   │   ├── OnboardingView.swift      # 23282 bytes - User onboarding
│   │   │   ├── AdvancedAnalyticsView.swift # 59074 bytes - Performance analytics
│   │   │   ├── WelcomeView.swift        # 25867 bytes - Welcome screen
│   │   │   ├── UserProfileView.swift    # 18483 bytes - Profile management
│   │   │   ├── SettingsView.swift        # 8103 bytes - App settings
│   │   │   └── [70+ other view files]
│   │   │
│   │   ├── Workout/                       # Workout-specific UI
│   │   │   ├── MainProgramWorkoutView.swift
│   │   │   ├── SCStarterWorkoutView.swift
│   │   │   └── [5 other workout views]
│   │   │
│   │   ├── SmartHubArticles/              # News & articles
│   │   │   └── [7 article files]
│   │   │
│   │   └── [15 other UI files]
│   │
│   ├── Utils/                             # Utility classes
│   │   └── [2 utility files]
│   │
│   └── Views/                             # Additional views
│       └── [7 view files]
│
├── SC40-V3-W Watch App/                   # Apple Watch App Target
│   ├── Assets.xcassets/                   # Watch-specific assets
│   ├── ContentView.swift                  # Watch app entry
│   ├── ContentViewWatch.swift             # Watch main interface
│   ├── EntryViewWatch.swift               # 16450 bytes - Watch entry point
│   ├── Info.plist                         # Watch app configuration
│   ├── SCStarterProSession.swift          # Watch starter session
│   │
│   ├── Models Watch/                      # Watch-specific models
│   │   └── [4 model files]
│   │
│   ├── Services Watch/                    # Watch-specific services
│   │   └── [4 service files]
│   │
│   ├── Utils Watch/                       # Watch utilities
│   │   └── [7 utility files]
│   │
│   ├── ViewModels Watch/                  # Watch view models
│   │   └── [2 view model files]
│   │
│   ├── Views Watch/                       # Watch UI components
│   │   ├── Auth/                          # Authentication views
│   │   │   └── [5 auth-related files]
│   │   │
│   │   ├── DaySessionCardsWatchView.swift # 40036 bytes - Main watch interface
│   │   ├── OnboardingRequiredView.swift   # Setup instructions
│   │   ├── StarterProWatchView.swift      # 24213 bytes - Premium features
│   │   ├── Workout/                       # Watch workout UI
│   │   │   └── [7 workout view files]
│   │   │
│   │   ├── Phases Watch/                  # Workout phase views
│   │   │   └── [5 phase files]
│   │   │
│   │   └── [15 other watch view files]
│   │
│   ├── WatchSessionManager.swift          # 68816 bytes - Watch connectivity
│   ├── WatchSessionPlaybackView.swift
│   └── WelcomeViewWatch.swift             # Watch welcome screen
│
├── SC40-V3.xcodeproj/                     # Xcode Project File
│   └── project.pbxproj                    # Project configuration
│
├── Documentation & Configuration/
│   ├── README.md                          # Project documentation
│   ├── APP_STORE_DESCRIPTION.md           # App Store listing
│   ├── PRIVACY_POLICY.md                  # Legal compliance
│   ├── TERMS_OF_SERVICE.md
│   ├── API_KEY_SETUP.md                   # API configuration
│   ├── APP_ICON_DESIGN_BRIEF.md           # Icon specifications
│   ├── TESTFLIGHT_SETUP_GUIDE.md          # Beta testing setup
│   └── [20+ other documentation files]
│
├── Build & Development Scripts/
│   ├── clean_build.sh                     # Build cleanup
│   ├── clear_derived_data.sh              # Cache clearing
│   ├── save_project.sh                    # Project backup
│   ├── xcode_cleanup.sh                   # Xcode maintenance
│   └── build_output.txt                   # Build logs
│
├── Test Files/
│   ├── SC40-V3Tests/                      # Unit tests
│   ├── TestTypes.swift                    # Test data types
│   ├── PyramidDemo.swift                  # Demo implementation
│   ├── WeekSimulation.swift               # Week simulation
│   └── validate_session_mixing.swift      # Session validation
│
└── Assets/
    ├── usa_sprinter.png                   # Marketing image
    └── mario-verduzco-NoFA4g6bS38-unsplash.jpg
```

## Architecture Overview

### **Project Structure Highlights:**

1. **📱 iOS App (SC40-V3/)**
   - **82 UI files** in `/UI/` directory
   - **42 model files** handling business logic
   - **7 service files** for external integrations
   - **Comprehensive session library** (84KB)

2. **⌚ Apple Watch App (SC40-V3-W Watch App/)**
   - **24 watch-specific view files**
   - **Cross-device connectivity** via WatchSessionManager
   - **Adaptive UI** for different watch sizes
   - **Offline capability** with ProgramPersistence

3. **🔗 Cross-Platform Features**
   - **WatchConnectivity** for iPhone ↔ Watch sync
   - **Shared models** and session libraries
   - **Unified user profiles** across devices
   - **Consistent haptic feedback** systems

4. **📚 Documentation**
   - **35+ markdown files** covering all aspects
   - **Setup guides** for development and deployment
   - **API documentation** and configuration
   - **Testing procedures** and troubleshooting

### **Key File Sizes:**
- **SessionLibrary.swift**: 84,684 bytes (main session database)
- **AdvancedAnalyticsView.swift**: 59,074 bytes (comprehensive analytics)
- **WatchSessionManager.swift**: 68,816 bytes (watch connectivity)
- **TrainingView.swift**: 37,211 bytes (main training interface)
- **UserProfileViewModel.swift**: 20,226 bytes (user management)

### **Development Scale:**
- **Total Lines of Code**: ~500,000+ (estimated)
- **Swift Files**: 200+ files across both targets
- **Features**: 50+ major features implemented
- **Platform Coverage**: iOS + watchOS with full feature parity

This structure supports a comprehensive sprint training app with cross-device synchronization, adaptive programming, and professional-grade analytics.

import SwiftUI
#if os(watchOS)
import WatchKit
#endif

struct HorizontalCardWatchView: View {
    @State private var selectedCardIndex = 1 // Start with User Profile card
    @State private var showSprintTimerPro = false
    @State private var showMainWorkout = false
    @State private var selectedSession: MockTrainingSession?
    
    // Mock data for compilation
    private let mockSessions = [
        MockTrainingSession(id: 1, week: 1, day: 1, type: "Speed", focus: "Acceleration"),
        MockTrainingSession(id: 2, week: 1, day: 2, type: "Endurance", focus: "Speed Endurance")
    ]
    
    // Adaptive sizing based on watch model
    private var watchSize: WatchSize {
        #if os(watchOS)
        let screenSize = WKInterfaceDevice.current().screenBounds.size
        if screenSize.width >= 410 { // Ultra
            return .ultra
        } else if screenSize.width >= 368 { // 45mm
            return .large
        } else { // 41mm and smaller
            return .standard
        }
        #else
        return .large // Default for preview/simulator
        #endif
    }
    
    enum WatchSize {
        case ultra, large, standard
        
        var cardSize: CGSize {
            switch self {
            case .ultra: return CGSize(width: 180, height: 120)
            case .large: return CGSize(width: 165, height: 110)
            case .standard: return CGSize(width: 150, height: 100)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .ultra: return 20
            case .large: return 18
            case .standard: return 16
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .ultra: return 12
            case .large: return 10
            case .standard: return 8
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Top section: Horizontally scrollable cards (independent of button)
                VStack {
                    TabView(selection: $selectedCardIndex) {
                        // Card 0: Sprint Timer Pro Content
                        SprintTimerProCardContent()
                            .frame(width: geometry.size.width * 0.85, height: geometry.size.height * 0.65)
                            .tag(0)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSprintTimerPro = true
                                }
                            }
                        
                        // Card 1: User Profile Content
                        UserProfileCardContent()
                            .frame(width: geometry.size.width * 0.85, height: geometry.size.height * 0.65)
                            .tag(1)
                        
                        // Cards 2+: Training Sessions Content
                        ForEach(mockSessions.indices, id: \.self) { index in
                            let session = mockSessions[index]
                            TrainingSessionCardContent(session: session)
                                .frame(width: geometry.size.width * 0.85, height: geometry.size.height * 0.65)
                                .tag(index + 2)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedSession = session
                                        showMainWorkout = true
                                    }
                                }
                        }
                    }
                    #if os(watchOS)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    #endif
                    .animation(.easeInOut(duration: 0.25), value: selectedCardIndex)
                    .frame(maxHeight: .infinity)
                    
                    // Spacer to push cards up and leave room for button
                    Spacer()
                }
                
                // Bottom section: Static "Start Sprint" button (completely independent)
                VStack {
                    Spacer() // Push button to bottom
                    
                    StartSprintButton(
                        selectedCardIndex: selectedCardIndex,
                        onAction: handleStartSprintAction
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8) // Safe area padding
                }
            }
        }
        .sheet(isPresented: $showSprintTimerPro) {
            Text("Sprint Timer Pro Configuration")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        }
        .sheet(item: $selectedSession) { session in
            Text("Training Session: \(session.type)")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        }
    }
    
    // MARK: - Action Handler
    private func handleStartSprintAction() {
        // Haptic feedback for button press
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
        
        withAnimation(.easeInOut(duration: 0.3)) {
            switch selectedCardIndex {
            case 0:
                // Sprint Timer Pro - Show configuration
                showSprintTimerPro = true
            case 1:
                // Profile - Could navigate to profile view or show stats
                // For now, no action needed
                break
            default:
                // Training Sessions - Start the selected workout
                if selectedCardIndex >= 2 && selectedCardIndex - 2 < mockSessions.count {
                    selectedSession = mockSessions[selectedCardIndex - 2]
                    showMainWorkout = true
                }
            }
        }
    }
    
}

// MARK: - Mock Data for Compilation
struct MockTrainingSession: Identifiable {
    let id: Int
    let week: Int
    let day: Int
    let type: String
    let focus: String
    
    var sprints: [MockSprintSet] {
        [MockSprintSet(distanceYards: 40, reps: 5, intensity: "Max")]
    }
}

struct MockSprintSet {
    let distanceYards: Int
    let reps: Int
    let intensity: String
}

// MARK: - Start Sprint Button (Apple Watch HIG Compliant)
struct StartSprintButton: View {
    let selectedCardIndex: Int
    let onAction: () -> Void
    
    var body: some View {
        Button(action: onAction) {
            HStack(spacing: 6) {
                Image(systemName: buttonIcon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                
                Text(buttonText)
                    .font(.system(size: 14, weight: .black))
                    .tracking(0.8)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44) // Apple Watch HIG minimum touch target
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.8, blue: 0.0),
                        Color(red: 1.0, green: 0.7, blue: 0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(22) // Half of height for pill shape
            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.9, blue: 0.2),
                                Color(red: 1.0, green: 0.6, blue: 0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(buttonPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: buttonPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            buttonPressed = pressing
        }, perform: {})
    }
    
    @State private var buttonPressed = false
    
    private var buttonIcon: String {
        switch selectedCardIndex {
        case 0: return "gearshape.fill" // Configuration icon
        case 1: return "person.crop.circle.fill" // Profile icon
        default: return "play.fill" // Start workout icon
        }
    }
    
    private var buttonText: String {
        switch selectedCardIndex {
        case 0: return "CONFIGURE"
        case 1: return "PROFILE"
        default: return "START SPRINT"
        }
    }
}

// MARK: - Sprint Timer Pro Card Content
struct SprintTimerProCardContent: View {
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            VStack(spacing: 8) {
                // Header
                VStack(spacing: 6) {
                    Text("Sprint Timer Pro")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("👑 PRO")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(6)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                
                // Description
                Text("Custom Sprint\nWorkouts")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Spacer(minLength: 8)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.9),
                            Color.black.opacity(0.7),
                            Color.black.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0).opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
    }
}

// MARK: - User Profile Card Content
struct UserProfileCardContent: View {
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            VStack(spacing: 8) {
                // Header
                VStack(spacing: 6) {
                    Text("Profile")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Sprint Training")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                // Stats
                VStack(spacing: 4) {
                    HStack {
                        Text("Level:")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("Intermediate")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    
                    HStack {
                        Text("PB:")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("5.25s")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    }
                }
                
                Spacer(minLength: 8)
                
                // Swipe indicator
                Text("← SWIPE FOR SESSIONS →")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.3)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.4),
                            Color.purple.opacity(0.4),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.cyan, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
    }
}

// MARK: - Training Session Card Content
struct TrainingSessionCardContent: View {
    let session: MockTrainingSession
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            VStack(spacing: 6) {
                // Header
                HStack {
                    Text("W\(session.week)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                        .cornerRadius(4)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    Spacer()
                    
                    Text("D\(session.day)")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                }
                
                // Session Type
                Text(session.type.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .tracking(0.8)
                
                // Focus
                Text(session.focus)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Sprint Details
                if let firstSprint = session.sprints.first {
                    VStack(spacing: 3) {
                        HStack(alignment: .bottom, spacing: 3) {
                            Text("\(firstSprint.reps)")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(.white)
                            
                            Text("×")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("\(firstSprint.distanceYards)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("YD")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Text(firstSprint.intensity.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.white)
                            .cornerRadius(3)
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    }
                }
                
                Spacer(minLength: 6)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.5),
                            Color.indigo.opacity(0.4),
                            Color.black.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.purple, .indigo.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
    }
}

// MARK: - User Profile Card (Legacy - Remove after testing)
struct UserProfileCard: View {
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            VStack(spacing: 8) {
                // Header
                VStack(spacing: 6) {
                    Text("Profile")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Sprint Training")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                // Stats
                VStack(spacing: 4) {
                    HStack {
                        Text("Level:")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("Intermediate")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    
                    HStack {
                        Text("PB:")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("5.25s")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    }
                }
                
                Spacer(minLength: 8)
                
                // Swipe indicator
                Text("← SWIPE FOR SESSIONS →")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(0.3)
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)
            
            // Golden button at bottom
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("VIEW PROFILE")
                        .font(.system(size: 11, weight: .black))
                        .tracking(0.5)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.7, blue: 0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.4),
                            Color.purple.opacity(0.4),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.cyan, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
    }
}

// MARK: - Training Session Watch Card (Legacy - Remove after testing)
struct TrainingSessionWatchCard: View {
    let session: MockTrainingSession
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            VStack(spacing: 6) {
                // Header
                HStack {
                    Text("W\(session.week)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                        .cornerRadius(4)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    
                    Spacer()
                    
                    Text("D\(session.day)")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                }
                
                // Session Type
                Text(session.type.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .tracking(0.8)
                
                // Focus
                Text(session.focus)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Sprint Details
                if let firstSprint = session.sprints.first {
                    VStack(spacing: 3) {
                        HStack(alignment: .bottom, spacing: 3) {
                            Text("\(firstSprint.reps)")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(.white)
                            
                            Text("×")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("\(firstSprint.distanceYards)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("YD")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Text(firstSprint.intensity.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.white)
                            .cornerRadius(3)
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                    }
                }
                
                Spacer(minLength: 6)
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)
            
            // Golden button at bottom
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("START WORKOUT")
                        .font(.system(size: 11, weight: .black))
                        .tracking(0.5)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.7, blue: 0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.5),
                            Color.indigo.opacity(0.4),
                            Color.black.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.purple, .indigo.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
    }
}

#Preview("Horizontal Cards - Dark") {
    HorizontalCardWatchView()
        .preferredColorScheme(.dark)
}

#Preview("Horizontal Cards - Light") {
    HorizontalCardWatchView()
        .preferredColorScheme(.light)
}

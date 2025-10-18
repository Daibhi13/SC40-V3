import Foundation
import Combine
import SwiftUI
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Intelligent platform manager that automatically determines the best workout experience based on user resources
@MainActor
class PlatformWorkoutManager: ObservableObject {
    static let shared = PlatformWorkoutManager()

    // Required for ObservableObject conformance
    var objectWillChange = ObservableObjectPublisher()

    @Published var preferredPlatform: WorkoutPlatform = .auto
    @Published var availablePlatforms: [WorkoutPlatform] = []
    @Published var isWatchAvailable = false
    @Published var watchConnectionStatus = "Checking..."
    
    enum WorkoutPlatform: String, CaseIterable, Identifiable {
        case auto = "auto"
        case phone = "phone" 
        case watch = "watch"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .auto: return "Smart Choice"
            case .phone: return "iPhone Only"
            case .watch: return "Apple Watch"
            }
        }
        
        var icon: String {
            switch self {
            case .auto: return "brain.head.profile"
            case .phone: return "iphone"
            case .watch: return "applewatch"
            }
        }
        
        var description: String {
            switch self {
            case .auto: return "Automatically choose the best option"
            case .phone: return "Use iPhone GPS and display"
            case .watch: return "Use Apple Watch for workouts"
            }
        }
    }
    
    private init() {
        checkAvailablePlatforms()
    }
    
    private func checkAvailablePlatforms() {
        availablePlatforms = [.phone] // Phone is always available
        
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            let session = WCSession.default
            isWatchAvailable = session.isPaired && session.isWatchAppInstalled
            
            if isWatchAvailable {
                availablePlatforms.append(.watch)
                watchConnectionStatus = session.isReachable ? "Connected" : "Available"
            } else {
                watchConnectionStatus = session.isPaired ? "App Not Installed" : "Not Paired"
            }
        } else {
            watchConnectionStatus = "Not Supported"
        }
        #else
        watchConnectionStatus = "Not Available"
        #endif
        
        availablePlatforms.append(.auto) // Auto is always an option
    }
    
    /// Intelligently determine the best platform for the current context
    func getOptimalPlatform() -> WorkoutPlatform {
        switch preferredPlatform {
        case .phone:
            return .phone
        case .watch:
            return isWatchAvailable ? .watch : .phone
        case .auto:
            // Smart logic: prefer watch if available and connected, otherwise use phone
            if isWatchAvailable {
                #if canImport(WatchConnectivity)
                return WCSession.default.isReachable ? .watch : .phone
                #else
                return .phone
                #endif
            }
            return .phone
        }
    }
    
    /// Check if a specific platform is currently available
    func isPlatformAvailable(_ platform: WorkoutPlatform) -> Bool {
        switch platform {
        case .phone:
            return true // iPhone is always available
        case .watch:
            return isWatchAvailable
        case .auto:
            return true // Auto is always available as it falls back to phone
        }
    }
    
    /// Get user-friendly status message
    func getStatusMessage() -> String {
        let optimal = getOptimalPlatform()
        
        switch optimal {
        case .phone:
            return isWatchAvailable ? "Using iPhone (Watch available as backup)" : "Using iPhone GPS tracking"
        case .watch:
            return "Using Apple Watch for optimal experience"
        case .auto:
            return "Smart mode will choose the best option automatically"
        }
    }
    
    /// Refresh platform availability (call when app becomes active)
    func refresh() {
        checkAvailablePlatforms()
    }
}

/// Smart workout selection view that adapts based on available platforms
struct SmartWorkoutPlatformSelector: View {
    @StateObject private var platformManager = PlatformWorkoutManager.shared
    @State private var showingWorkout = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Choose Your Workout Experience")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("SC40 adapts to your available devices for the best sprint training experience")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(platformManager.availablePlatforms) { platform in
                    PlatformOptionCard(
                        platform: platform,
                        isSelected: platformManager.preferredPlatform == platform,
                        isAvailable: platformManager.isPlatformAvailable(platform)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            platformManager.preferredPlatform = platform
                        }
                    }
                }
            }
            
            VStack(spacing: 12) {
                Text(platformManager.getStatusMessage())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if platformManager.isWatchAvailable {
                    HStack {
                        Image(systemName: "applewatch")
                            .foregroundColor(.green)
                        Text("Apple Watch: \(platformManager.watchConnectionStatus)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button(action: {
                showingWorkout = true
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Workout")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding()
        .sheet(isPresented: $showingWorkout) {
            SmartWorkoutLauncher()
        }
        .onAppear {
            platformManager.refresh()
        }
    }
}

struct PlatformOptionCard: View {
    let platform: PlatformWorkoutManager.WorkoutPlatform
    let isSelected: Bool
    let isAvailable: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: platform.icon)
                    .font(.title)
                    .foregroundColor(isAvailable ? (isSelected ? .white : .blue) : .gray)
                
                Text(platform.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isAvailable ? (isSelected ? .white : .primary) : .gray)
                
                Text(platform.description)
                    .font(.caption)
                    .foregroundColor(isAvailable ? (isSelected ? .white.opacity(0.8) : .secondary) : .gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ? 
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.clear : Color.gray.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
            .opacity(isAvailable ? 1.0 : 0.6)
        }
        .disabled(!isAvailable)
    }
}

/// Smart launcher that automatically chooses the appropriate workout view
struct SmartWorkoutLauncher: View {
    @StateObject private var platformManager = PlatformWorkoutManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                switch platformManager.getOptimalPlatform() {
                case .phone:
                    Text("Phone Workout Ready")
                        .font(.title2)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                case .watch:
                    Text("Watch Workout Ready")
                        .font(.title2)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                case .auto:
                    // Auto mode: show dynamic selection based on current status
                    Text("Auto Mode: Selecting Best Platform")
                        .font(.title2)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("SC40 Workout")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        // dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(platformManager.availablePlatforms) { platform in
                            if platformManager.isPlatformAvailable(platform) {
                                Button(action: {
                                    platformManager.preferredPlatform = platform
                                }) {
                                    HStack {
                                        Text(platform.displayName)
                                        if platformManager.preferredPlatform == platform {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            #endif
        }
    }
}

/// Auto mode view that dynamically shows the best option
struct AutoWorkoutView: View {
    @StateObject private var platformManager = PlatformWorkoutManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                
                Text("Smart Workout Mode")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("SC40 has analyzed your available devices and selected the optimal workout experience")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: platformManager.getOptimalPlatform().icon)
                        .font(.title3)
                        .foregroundColor(.green)
                    
                    Text("Selected: \(platformManager.getOptimalPlatform().displayName)")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                Text(platformManager.getStatusMessage())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Launch the optimal platform
            switch platformManager.getOptimalPlatform() {
            case .phone:
                Button("Start Phone Workout") {
                    // Launch phone workout
                    print("Starting phone workout")
                }
            case .watch:
                Text("Starting Apple Watch workout...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            case .auto:
                EmptyView()
            }
            
            Spacer()
        }
        .padding()
    }
}

/// Placeholder for watch workout launcher
struct WatchWorkoutLauncherView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "applewatch")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("Apple Watch Workout")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your workout will start on your Apple Watch. Please check your watch to begin.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Launch on Watch") {
                // Send launch command to watch
                #if canImport(WatchConnectivity) && !os(watchOS)
                print("Would launch watch workout")
                #endif
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
}

#Preview {
    SmartWorkoutPlatformSelector()
}

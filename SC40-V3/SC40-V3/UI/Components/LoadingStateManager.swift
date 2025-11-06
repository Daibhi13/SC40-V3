import SwiftUI
import Combine

// MARK: - Loading State Manager
// Centralized loading state management for the entire app

@MainActor
class LoadingStateManager: ObservableObject {
    static let shared = LoadingStateManager()
    
    @Published var isOnboarding = false
    @Published var isGeneratingProgram = false
    @Published var isSyncingWatch = false
    @Published var isAuthenticating = false
    @Published var isLoadingTraining = false
    
    @Published var onboardingProgress: Double = 0.0
    @Published var programGenerationProgress: Double = 0.0
    @Published var watchSyncProgress: Double = 0.0
    
    @Published var currentOperation = ""
    @Published var estimatedTimeRemaining: TimeInterval = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Monitor ProgressiveLoadingManager
        ProgressiveLoadingManager.shared.$isGeneratingProgram
            .assign(to: \.isGeneratingProgram, on: self)
            .store(in: &cancellables)
        
        ProgressiveLoadingManager.shared.$generationProgress
            .assign(to: \.programGenerationProgress, on: self)
            .store(in: &cancellables)
        
        ProgressiveLoadingManager.shared.$currentStage
            .assign(to: \.currentOperation, on: self)
            .store(in: &cancellables)
        
        ProgressiveLoadingManager.shared.$estimatedTimeRemaining
            .assign(to: \.estimatedTimeRemaining, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Loading State Control
    
    func startOnboarding() {
        isOnboarding = true
        onboardingProgress = 0.0
        currentOperation = "Starting onboarding..."
    }
    
    func updateOnboardingProgress(_ progress: Double, operation: String = "") {
        onboardingProgress = progress
        if !operation.isEmpty {
            currentOperation = operation
        }
    }
    
    func completeOnboarding() {
        isOnboarding = false
        onboardingProgress = 1.0
        currentOperation = "Onboarding complete"
    }
    
    func startAuthentication() {
        isAuthenticating = true
        currentOperation = "Authenticating..."
    }
    
    func completeAuthentication() {
        isAuthenticating = false
        currentOperation = ""
    }
    
    func startWatchSync() {
        isSyncingWatch = true
        watchSyncProgress = 0.0
        currentOperation = "Syncing with Apple Watch..."
    }
    
    func updateWatchSyncProgress(_ progress: Double) {
        watchSyncProgress = progress
    }
    
    func completeWatchSync() {
        isSyncingWatch = false
        watchSyncProgress = 1.0
        currentOperation = "Watch sync complete"
    }
    
    func startTrainingLoad() {
        isLoadingTraining = true
        currentOperation = "Loading training data..."
    }
    
    func completeTrainingLoad() {
        isLoadingTraining = false
        currentOperation = ""
    }
    
    // MARK: - Computed Properties
    
    var isAnyOperationInProgress: Bool {
        isOnboarding || isGeneratingProgram || isSyncingWatch || isAuthenticating || isLoadingTraining
    }
    
    var overallProgress: Double {
        let activeOperations = [
            isOnboarding ? onboardingProgress : 1.0,
            isGeneratingProgram ? programGenerationProgress : 1.0,
            isSyncingWatch ? watchSyncProgress : 1.0
        ].filter { $0 < 1.0 }
        
        if activeOperations.isEmpty {
            return 1.0
        }
        
        return activeOperations.reduce(0, +) / Double(activeOperations.count)
    }
    
    func resetAllStates() {
        isOnboarding = false
        isGeneratingProgram = false
        isSyncingWatch = false
        isAuthenticating = false
        isLoadingTraining = false
        
        onboardingProgress = 0.0
        programGenerationProgress = 0.0
        watchSyncProgress = 0.0
        
        currentOperation = ""
        estimatedTimeRemaining = 0
    }
}

// MARK: - Loading Overlay View

struct LoadingOverlayView: View {
    @StateObject private var loadingManager = LoadingStateManager.shared
    
    var body: some View {
        if loadingManager.isAnyOperationInProgress {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                // Loading content
                VStack(spacing: 24) {
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: loadingManager.overallProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: loadingManager.overallProgress)
                        
                        Text("\(Int(loadingManager.overallProgress * 100))%")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }
                    
                    // Operation Text
                    VStack(spacing: 8) {
                        Text(loadingManager.currentOperation)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if loadingManager.estimatedTimeRemaining > 0 {
                            Text("About \(Int(loadingManager.estimatedTimeRemaining)) seconds remaining")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    // Individual Progress Indicators
                    VStack(spacing: 12) {
                        if loadingManager.isOnboarding {
                            ProgressIndicatorRow(
                                title: "Onboarding",
                                progress: loadingManager.onboardingProgress,
                                isActive: true
                            )
                        }
                        
                        if loadingManager.isGeneratingProgram {
                            ProgressIndicatorRow(
                                title: "Generating Program",
                                progress: loadingManager.programGenerationProgress,
                                isActive: true
                            )
                        }
                        
                        if loadingManager.isSyncingWatch {
                            ProgressIndicatorRow(
                                title: "Syncing Watch",
                                progress: loadingManager.watchSyncProgress,
                                isActive: true
                            )
                        }
                        
                        if loadingManager.isAuthenticating {
                            ProgressIndicatorRow(
                                title: "Authenticating",
                                progress: 0.5,
                                isActive: true,
                                isIndeterminate: true
                            )
                        }
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(radius: 20)
                )
                .padding(.horizontal, 40)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            .animation(.easeInOut(duration: 0.3), value: loadingManager.isAnyOperationInProgress)
        }
    }
}

// MARK: - Progress Indicator Row

struct ProgressIndicatorRow: View {
    let title: String
    let progress: Double
    let isActive: Bool
    let isIndeterminate: Bool
    
    init(title: String, progress: Double, isActive: Bool, isIndeterminate: Bool = false) {
        self.title = title
        self.progress = progress
        self.isActive = isActive
        self.isIndeterminate = isIndeterminate
    }
    
    var body: some View {
        HStack {
            // Status Icon
            if isActive {
                if isIndeterminate {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: progress >= 1.0 ? "checkmark.circle.fill" : "circle.dotted")
                        .foregroundColor(progress >= 1.0 ? .green : .white)
                }
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
            
            Spacer()
            
            // Progress Percentage
            if !isIndeterminate {
                Text("\(Int(progress * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(isActive ? .white : .white.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.white.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - View Extensions

extension View {
    func withLoadingOverlay() -> some View {
        ZStack {
            self
            LoadingOverlayView()
        }
    }
}

#Preview {
    VStack {
        Text("App Content")
            .font(.largeTitle)
            .padding()
        
        Button("Start Loading") {
            LoadingStateManager.shared.startOnboarding()
            LoadingStateManager.shared.updateOnboardingProgress(0.3, operation: "Setting up profile...")
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
    .withLoadingOverlay()
}

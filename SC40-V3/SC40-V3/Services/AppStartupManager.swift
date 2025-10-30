import Foundation
import SwiftUI
import Combine
import os.log

#if canImport(WatchConnectivity) && os(iOS)
import WatchConnectivity
#endif

// MARK: - App Startup Flow Manager
// Implements the comprehensive startup & connectivity flow specification
@MainActor
class AppStartupManager: ObservableObject {
    static let shared = AppStartupManager()
    
    // MARK: - Published State
    @Published var startupPhase: StartupPhase = .splash
    @Published var syncProgress: Double = 0.0
    @Published var syncMessage: String = "Initializing..."
    @Published var isConnectivityCheckComplete = false
    @Published var canProceedToMainView = false
    @Published var syncError: String?
    
    // MARK: - Dependencies
    private let watchManager = WatchConnectivityManager.shared
    private let syncManager = TrainingSynchronizationManager.shared
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "AppStartup")
    
    private var cancellables = Set<AnyCancellable>()
    private var syncRetryTimer: Timer?
    private let maxRetryAttempts = 10
    private var currentRetryAttempt = 0
    
    // MARK: - Startup Phases
    enum StartupPhase {
        case splash                 // Initial loading screen
        case connectivityCheck      // Checking watch connection
        case syncBuffer            // Syncing training data
        case syncError             // Sync failed, showing retry
        case ready                 // Ready to proceed to main view
    }
    
    private init() {
        setupConnectivityObservers()
    }
    
    // MARK: - 1. APP LAUNCH SEQUENCE
    func onAppLaunch() {
        logger.info("🚀 App launch sequence initiated")
        showSplashScreen()
        
        // Small delay to show splash before starting connectivity check
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.initConnectivityCheck()
        }
    }
    
    private func showSplashScreen() {
        startupPhase = .splash
        syncMessage = "Sprint Coach 40"
        logger.info("📱 Displaying splash screen")
    }
    
    // MARK: - 2. CONNECTIVITY CHECK
    private func initConnectivityCheck() {
        logger.info("🔍 Initiating connectivity check")
        startupPhase = .connectivityCheck
        syncMessage = "Checking device connectivity..."
        syncProgress = 0.1
        
        let isPaired = checkWatchConnection()
        let isSynced = checkTrainingSync()
        
        logger.info("📊 Connectivity status - Paired: \(isPaired), Synced: \(isSynced)")
        
        if isPaired && isSynced {
            logger.info("✅ Already synced - proceeding to main view")
            proceedToMainView()
        } else {
            logger.info("🔄 Sync required - showing sync buffer UI")
            showSyncBufferUI()
            attemptSessionSync()
        }
    }
    
    private func checkWatchConnection() -> Bool {
        let isConnected = watchManager.isWatchConnected
        logger.info("⌚ Watch connection status: \(isConnected)")
        return isConnected
    }
    
    private func checkTrainingSync() -> Bool {
        let isSynced = watchManager.trainingSessionsSynced && watchManager.userProfileSynced
        logger.info("📋 Training sync status: \(isSynced)")
        return isSynced
    }
    
    // MARK: - 3. SYNC LOGIC
    private func showSyncBufferUI() {
        startupPhase = .syncBuffer
        syncMessage = "Syncing your training sessions..."
        syncProgress = 0.2
        currentRetryAttempt = 0
        logger.info("🔄 Showing sync buffer UI")
    }
    
    private func attemptSessionSync() {
        guard currentRetryAttempt < maxRetryAttempts else {
            logger.error("❌ Max retry attempts reached")
            showSyncError("Unable to sync after multiple attempts. Please check your connection.")
            return
        }
        
        currentRetryAttempt += 1
        logger.info("🔄 Sync attempt \(self.currentRetryAttempt)/\(self.maxRetryAttempts)")
        
        syncMessage = "Syncing training plan... (Attempt \(currentRetryAttempt))"
        syncProgress = 0.3 + (Double(currentRetryAttempt) / Double(maxRetryAttempts)) * 0.4
        
        Task {
            do {
                try await sendTrainingPlanToWatch()
                await MainActor.run {
                    self.updateSyncStatus(true)
                    self.proceedToMainView()
                }
            } catch {
                await MainActor.run {
                    self.handleSyncError(error)
                }
            }
        }
    }
    
    private func sendTrainingPlanToWatch() async throws {
        logger.info("📤 Sending training plan to watch")
        
        // Use the existing sync manager to send training data
        // Note: Using default values for level and days since this is startup sync
        await syncManager.synchronizeTrainingProgram(level: .beginner, days: 28)
        
        logger.info("✅ Training plan sync completed")
    }
    
    private func updateSyncStatus(_ success: Bool) {
        if success {
            logger.info("✅ Sync status updated to success")
            syncProgress = 1.0
            syncMessage = "Sync complete!"
            
            // Update watch manager sync flags
            watchManager.trainingSessionsSynced = true
            watchManager.userProfileSynced = true
        }
    }
    
    private func handleSyncError(_ error: Error) {
        logger.error("❌ Sync error: \(error.localizedDescription)")
        
        if watchManager.isWatchConnected {
            // Watch is connected but sync failed - retry
            showSyncError("Sync failed. Retrying...")
            retrySyncAfterDelay(3000) // 3 seconds
        } else {
            // Watch not connected
            showSyncError("Move closer to your Apple Watch to connect")
            retrySyncAfterDelay(5000) // 5 seconds
        }
    }
    
    // MARK: - 4. PROCEED TO MAIN VIEW
    private func proceedToMainView() {
        logger.info("🎯 Proceeding to main view")
        startupPhase = .ready
        syncProgress = 1.0
        syncMessage = "Ready!"
        canProceedToMainView = true
        isConnectivityCheckComplete = true
        
        // Send UI update to watch
        sendUIUpdateToWatch("SHOW_TRAINING_VIEW")
        
        // Small delay for smooth transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.hideSplashScreen()
        }
    }
    
    private func hideSplashScreen() {
        logger.info("📱 Hiding splash screen")
        // The UI will handle the transition based on canProceedToMainView
    }
    
    private func sendUIUpdateToWatch(_ command: String) {
        logger.info("📤 Sending UI update to watch: \(command)")
        
        let message = [
            "type": "UI_UPDATE",
            "command": command,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        watchManager.sendMessage(message) { success in
            if success {
                self.logger.info("✅ UI update sent to watch successfully")
            } else {
                self.logger.warning("⚠️ Failed to send UI update to watch")
            }
        }
    }
    
    // MARK: - 7. EDGE CASE HANDLING
    private func showSyncError(_ message: String) {
        logger.warning("⚠️ Sync error: \(message)")
        startupPhase = .syncError
        syncError = message
        syncMessage = message
    }
    
    private func retrySyncAfterDelay(_ milliseconds: Int) {
        logger.info("⏰ Scheduling retry in \(milliseconds)ms")
        
        syncRetryTimer?.invalidate()
        syncRetryTimer = Timer.scheduledTimer(withTimeInterval: Double(milliseconds) / 1000.0, repeats: false) { _ in
            Task { @MainActor in
                self.attemptSessionSync()
            }
        }
    }
    
    // MARK: - Connectivity Observers
    private func setupConnectivityObservers() {
        // Watch connection status changes
        watchManager.$isWatchConnected
            .sink { [weak self] isConnected in
                self?.logger.info("⌚ Watch connection changed: \(isConnected)")
                if isConnected && self?.startupPhase == .syncError {
                    // Watch reconnected during error state - retry sync
                    self?.attemptSessionSync()
                }
            }
            .store(in: &cancellables)
        
        // Watch reachability changes
        watchManager.$isWatchReachable
            .sink { [weak self] isReachable in
                self?.logger.info("📡 Watch reachability changed: \(isReachable)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface
    func retrySync() {
        logger.info("🔄 Manual retry requested")
        currentRetryAttempt = 0
        attemptSessionSync()
    }
    
    func skipSync() {
        logger.info("⏭️ Sync skipped by user")
        proceedToMainView()
    }
    
    func reset() {
        logger.info("🔄 Resetting startup manager")
        startupPhase = .splash
        syncProgress = 0.0
        syncMessage = "Initializing..."
        isConnectivityCheckComplete = false
        canProceedToMainView = false
        syncError = nil
        currentRetryAttempt = 0
        syncRetryTimer?.invalidate()
    }
    
    deinit {
        syncRetryTimer?.invalidate()
    }
}

// MARK: - WatchConnectivityManager Extension
extension WatchConnectivityManager {
    func sendMessage(_ message: [String: Any], completion: @escaping (Bool) -> Void) {
        #if canImport(WatchConnectivity) && os(iOS)
        guard isWatchReachable else {
            completion(false)
            return
        }
        
        WCSession.default.sendMessage(message, replyHandler: { _ in
            completion(true)
        }, errorHandler: { error in
            Logger(subsystem: "com.accelerate.sc40", category: "WatchConnectivity")
                .error("Failed to send message: \(error.localizedDescription)")
            completion(false)
        })
        #else
        completion(false)
        #endif
    }
}

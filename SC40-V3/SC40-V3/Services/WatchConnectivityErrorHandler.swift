import Foundation
import Combine
import WatchConnectivity
import os.log

// MARK: - Enhanced WatchConnectivity Error Handling and Recovery

@MainActor
class WatchConnectivityErrorHandler: ObservableObject {
    static let shared = WatchConnectivityErrorHandler()
    
    @Published var connectionState: ConnectionState = .unknown
    @Published var lastError: WatchConnectivityError?
    @Published var retryCount: Int = 0
    @Published var isRecovering: Bool = false
    
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "WatchConnectivityErrorHandler")
    private let maxRetries = 5
    private var retryTimer: Timer?
    
    enum ConnectionState: CustomStringConvertible {
        case unknown
        case connected
        case disconnected
        case error(WatchConnectivityError)
        case recovering
        
        var description: String {
            switch self {
            case .unknown: return "unknown"
            case .connected: return "connected"
            case .disconnected: return "disconnected"
            case .error(let error): return "error(\(error))"
            case .recovering: return "recovering"
            }
        }
    }
    
    private init() {}
    
    deinit {
        retryTimer?.invalidate()
        retryTimer = nil
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error, context: String = "") {
        let watchError = WatchConnectivityError.from(error, context: context)
        
        logger.error("WatchConnectivity Error [\(context)]: \(watchError.localizedDescription)")
        
        lastError = watchError
        connectionState = .error(watchError)
        
        // Determine recovery strategy based on error type
        switch watchError {
        case .sessionNotActivated, .watchNotPaired, .appNotInstalled:
            // Critical errors - immediate recovery attempt
            initiateImmediateRecovery()
            
        case .messageTimeout, .timeout, .transferFailed:
            // Transient errors - retry with backoff
            initiateRetryWithBackoff()
            
        case .watchNotReachable:
            // Connectivity issue - wait and retry
            initiateConnectivityRecovery()
            
        case .unknown:
            // Unknown error - conservative recovery
            initiateConservativeRecovery()
        }
    }
    
    // MARK: - Recovery Strategies
    
    private func initiateImmediateRecovery() {
        guard !isRecovering else { return }
        
        isRecovering = true
        connectionState = .recovering
        
        logger.info("🔄 Initiating immediate recovery...")
        
        Task {
            // Step 1: Check session state
            await checkSessionState()
            
            // Step 2: Reactivate if needed
            if WCSession.default.activationState != .activated {
                await reactivateSession()
            }
            
            // Step 3: Verify connectivity
            await verifyConnectivity()
            
            await MainActor.run {
                self.isRecovering = false
                self.updateConnectionState()
            }
        }
    }
    
    private func initiateRetryWithBackoff() {
        guard retryCount < maxRetries else {
            logger.error("❌ Max retries reached - giving up")
            connectionState = .error(lastError ?? .unknown("Max retries exceeded"))
            return
        }
        
        retryCount += 1
        isRecovering = true
        
        let backoffDelay = min(pow(2.0, Double(retryCount)), 30.0) // Exponential backoff, max 30s
        
        logger.info("🔄 Retry attempt \(self.retryCount)/\(self.maxRetries) in \(backoffDelay)s")
        
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: backoffDelay, repeats: false) { _ in
            Task { @MainActor in
                await self.attemptRecovery()
            }
        }
    }
    
    private func initiateConnectivityRecovery() {
        guard !isRecovering else { return }
        
        isRecovering = true
        connectionState = .recovering
        
        logger.info("🔄 Initiating connectivity recovery...")
        
        // Monitor reachability changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WCSessionReachabilityDidChange"),
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await self.verifyConnectivity()
                self.isRecovering = false
                self.updateConnectionState()
            }
        }
        
        // Also try periodic checks
        schedulePeriodicConnectivityCheck()
    }
    
    private func initiateConservativeRecovery() {
        guard !isRecovering else { return }
        
        isRecovering = true
        connectionState = .recovering
        
        logger.info("🔄 Initiating conservative recovery...")
        
        // Wait longer before attempting recovery
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            Task { @MainActor in
                await self.attemptRecovery()
            }
        }
    }
    
    // MARK: - Recovery Operations
    
    private func checkSessionState() async {
        let session = WCSession.default
        
        logger.info("📊 Session State Check:")
        logger.info("  - Supported: \(WCSession.isSupported())")
        logger.info("  - Activation: \(session.activationState.rawValue)")
        logger.info("  - Paired: \(session.isPaired)")
        logger.info("  - App Installed: \(session.isWatchAppInstalled)")
        logger.info("  - Reachable: \(session.isReachable)")
    }
    
    private func reactivateSession() async {
        logger.info("🔄 Reactivating WCSession...")
        
        let session = WCSession.default
        
        // Reset delegate if needed
        if session.delegate == nil {
            session.delegate = WatchConnectivityManager.shared
        }
        
        // Activate session
        session.activate()
        
        // Wait for activation
        for _ in 0..<30 { // Wait up to 3 seconds
            if session.activationState == .activated {
                logger.info("✅ Session reactivated successfully")
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        logger.warning("⚠️ Session reactivation timed out")
    }
    
    private func verifyConnectivity() async {
        let session = WCSession.default
        
        guard session.activationState == .activated else {
            logger.warning("⚠️ Cannot verify connectivity - session not activated")
            return
        }
        
        guard session.isPaired && session.isWatchAppInstalled else {
            logger.warning("⚠️ Cannot verify connectivity - watch not paired or app not installed")
            return
        }
        
        if session.isReachable {
            // Send ping to verify actual connectivity
            await sendConnectivityPing()
        } else {
            logger.info("📱 Watch not currently reachable")
        }
    }
    
    private func sendConnectivityPing() async {
        let session = WCSession.default
        
        let pingMessage: [String: Any] = [
            "type": "connectivity_ping",
            "timestamp": Date().timeIntervalSince1970,
            "recovery_attempt": true
        ]
        
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                session.sendMessage(pingMessage) { reply in
                    self.logger.info("✅ Connectivity ping successful")
                    continuation.resume()
                } errorHandler: { error in
                    self.logger.error("❌ Connectivity ping failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            logger.error("❌ Ping verification failed: \(error.localizedDescription)")
        }
    }
    
    private func attemptRecovery() async {
        logger.info("🔄 Attempting recovery...")
        
        await checkSessionState()
        
        if WCSession.default.activationState != .activated {
            await reactivateSession()
        }
        
        await verifyConnectivity()
        
        isRecovering = false
        updateConnectionState()
        
        // Reset retry count on successful recovery
        if case .connected = connectionState {
            retryCount = 0
            logger.info("✅ Recovery successful")
        }
    }
    
    private func schedulePeriodicConnectivityCheck() {
        retryTimer?.invalidate()
        retryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                if WCSession.default.isReachable {
                    await self.verifyConnectivity()
                    self.isRecovering = false
                    self.updateConnectionState()
                    self.retryTimer?.invalidate()
                }
            }
        }
    }
    
    // MARK: - State Management
    
    private func updateConnectionState() {
        let session = WCSession.default
        
        if session.activationState == .activated && session.isPaired && session.isWatchAppInstalled {
            if session.isReachable {
                connectionState = .connected
                lastError = nil
            } else {
                connectionState = .disconnected
            }
        } else {
            connectionState = .error(lastError ?? .sessionNotActivated)
        }
        
        logger.info("📊 Connection state updated: \(self.connectionState)")
    }
    
    // MARK: - Public Interface
    
    func resetErrorState() {
        lastError = nil
        retryCount = 0
        isRecovering = false
        retryTimer?.invalidate()
        updateConnectionState()
    }
    
    func forceRecovery() {
        logger.info("🔄 Force recovery requested")
        resetErrorState()
        initiateImmediateRecovery()
    }
}

// MARK: - Enhanced WatchConnectivity Errors

enum WatchConnectivityError: LocalizedError {
    case sessionNotActivated
    case watchNotPaired
    case appNotInstalled
    case watchNotReachable
    case messageTimeout
    case timeout
    case transferFailed(String)
    case unknown(String)
    
    static func from(_ error: Error, context: String = "") -> WatchConnectivityError {
        if let wcError = error as? WCError {
            switch wcError.code {
            case .sessionNotActivated:
                return .sessionNotActivated
            case .notReachable:
                return .watchNotPaired
            case .messageReplyTimedOut:
                return .messageTimeout
            case .transferTimedOut:
                return .transferFailed("Transfer timed out")
            default:
                return .unknown("WCError: \(wcError.localizedDescription)")
            }
        }
        
        return .unknown("\(context): \(error.localizedDescription)")
    }
    
    var errorDescription: String? {
        switch self {
        case .sessionNotActivated:
            return "Watch session not activated. Please restart the app."
        case .watchNotPaired:
            return "Apple Watch not paired. Please pair your watch in the Watch app."
        case .appNotInstalled:
            return "Sprint Coach app not installed on Apple Watch. Please install from the Watch app."
        case .watchNotReachable:
            return "Apple Watch not reachable. Make sure your watch is nearby and unlocked."
        case .messageTimeout:
            return "Communication with Apple Watch timed out. Please try again."
        case .timeout:
            return "Watch communication timed out. Please try again."
        case .transferFailed(let reason):
            return "Data transfer failed: \(reason)"
        case .unknown(let description):
            return "Connection error: \(description)"
        }
    }
    
    var recoveryAction: String {
        switch self {
        case .sessionNotActivated:
            return "Restart app"
        case .watchNotPaired:
            return "Pair watch"
        case .appNotInstalled:
            return "Install watch app"
        case .watchNotReachable:
            return "Check watch connection"
        case .messageTimeout, .timeout, .transferFailed:
            return "Retry"
        case .unknown:
            return "Try again"
        }
    }
}

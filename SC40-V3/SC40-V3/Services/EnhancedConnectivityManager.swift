import Foundation
import WatchConnectivity
import Combine
import os.log

// MARK: - Enhanced Connectivity Manager
// Unified, resilient connectivity system with advanced features

@MainActor
class EnhancedConnectivityManager: NSObject, ObservableObject {
    static let shared = EnhancedConnectivityManager()
    
    // MARK: - Enhanced Published Properties
    @Published var connectionState: ConnectionState = .initializing
    @Published var syncQuality: SyncQuality = .unknown
    @Published var dataTransferRate: Double = 0.0 // KB/s
    @Published var latency: TimeInterval = 0.0 // milliseconds
    @Published var reliabilityScore: Double = 0.0 // 0.0 - 1.0
    
    // Advanced monitoring
    @Published var activeConnections: Int = 0
    @Published var queuedMessages: Int = 0
    @Published var failedTransfers: Int = 0
    @Published var successfulTransfers: Int = 0
    
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "EnhancedConnectivity")
    private var cancellables = Set<AnyCancellable>()
    
    // Enhanced retry system
    private var messageQueue: [QueuedMessage] = []
    private var retryTimer: Timer?
    private let maxRetryAttempts = 5
    private let baseRetryDelay: TimeInterval = 1.0
    
    // Performance monitoring
    private var transferStartTimes: [String: Date] = [:]
    private var recentLatencies: [TimeInterval] = []
    private var recentSuccessRates: [Bool] = []
    
    enum ConnectionState: Equatable {
        case initializing
        case connected
        case degraded
        case disconnected
        case error(String)
        
        var description: String {
            switch self {
            case .initializing: return "Initializing connection..."
            case .connected: return "Connected and optimal"
            case .degraded: return "Connected but degraded performance"
            case .disconnected: return "Disconnected"
            case .error(let message): return "Error: \(message)"
            }
        }
        
        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.initializing, .initializing),
                 (.connected, .connected),
                 (.degraded, .degraded),
                 (.disconnected, .disconnected):
                return true
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    enum SyncQuality {
        case unknown
        case excellent  // < 100ms latency, > 95% success
        case good       // < 500ms latency, > 85% success  
        case fair       // < 1000ms latency, > 70% success
        case poor       // > 1000ms latency, < 70% success
        
        var color: String {
            switch self {
            case .unknown: return "gray"
            case .excellent: return "green"
            case .good: return "blue"
            case .fair: return "orange"
            case .poor: return "red"
            }
        }
    }
    
    struct QueuedMessage {
        let id: UUID
        let data: [String: Any]
        let priority: MessagePriority
        let attempts: Int
        let createdAt: Date
        let maxRetries: Int
        
        enum MessagePriority: Int, CaseIterable {
            case critical = 0    // Workout control, safety
            case high = 1        // Real-time data, user actions
            case normal = 2      // Session sync, updates
            case low = 3         // Background sync, analytics
            
            var retryDelay: TimeInterval {
                switch self {
                case .critical: return 0.5
                case .high: return 1.0
                case .normal: return 2.0
                case .low: return 5.0
                }
            }
        }
    }
    
    private override init() {
        super.init()
        setupEnhancedConnectivity()
        startPerformanceMonitoring()
    }
    
    // MARK: - Enhanced Setup
    
    private func setupEnhancedConnectivity() {
        guard WCSession.isSupported() else {
            connectionState = .error("WatchConnectivity not supported")
            return
        }
        
        WCSession.default.delegate = self
        WCSession.default.activate()
        
        // Start connection quality monitoring
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                self.assessConnectionQuality()
            }
        }
        
        logger.info("Enhanced connectivity system initialized")
    }
    
    private func startPerformanceMonitoring() {
        // Monitor performance metrics every 10 seconds
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task { @MainActor in
                self.updatePerformanceMetrics()
            }
        }
    }
    
    // MARK: - Enhanced Message Sending
    
    func sendMessage(_ data: [String: Any], priority: QueuedMessage.MessagePriority = .normal) async -> Bool {
        let messageId = UUID()
        let startTime = Date()
        transferStartTimes[messageId.uuidString] = startTime
        
        // Add to queue for retry handling
        let queuedMessage = QueuedMessage(
            id: messageId,
            data: data,
            priority: priority,
            attempts: 0,
            createdAt: startTime,
            maxRetries: priority == .critical ? 10 : maxRetryAttempts
        )
        
        return await sendMessageWithEnhancedRetry(queuedMessage)
    }
    
    private func sendMessageWithEnhancedRetry(_ message: QueuedMessage) async -> Bool {
        guard WCSession.default.isReachable else {
            // Queue for later if not reachable
            messageQueue.append(message)
            queuedMessages = messageQueue.count
            return false
        }
        
        let startTime = Date()
        
        do {
            try await withTimeout(seconds: message.priority.retryDelay * 2) {
                try await withCheckedThrowingContinuation { continuation in
                    WCSession.default.sendMessage(message.data) { reply in
                        let latency = Date().timeIntervalSince(startTime) * 1000 // Convert to ms
                        self.recordSuccessfulTransfer(latency: latency)
                        continuation.resume()
                    } errorHandler: { error in
                        self.recordFailedTransfer()
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            successfulTransfers += 1
            return true
            
        } catch {
            failedTransfers += 1
            
            // Exponential backoff retry
            if message.attempts < message.maxRetries {
                let delay = message.priority.retryDelay * pow(2.0, Double(message.attempts))
                
                logger.info("Retrying message after \(delay)s (attempt \(message.attempts + 1)/\(message.maxRetries))")
                
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                let retryMessage = QueuedMessage(
                    id: message.id,
                    data: message.data,
                    priority: message.priority,
                    attempts: message.attempts + 1,
                    createdAt: message.createdAt,
                    maxRetries: message.maxRetries
                )
                
                return await sendMessageWithEnhancedRetry(retryMessage)
            }
            
            logger.error("Message failed after \(message.maxRetries) attempts: \(error)")
            return false
        }
    }
    
    // MARK: - Performance Monitoring
    
    private func recordSuccessfulTransfer(latency: TimeInterval) {
        recentLatencies.append(latency)
        recentSuccessRates.append(true)
        
        // Keep only recent data (last 50 transfers)
        if recentLatencies.count > 50 {
            recentLatencies.removeFirst()
        }
        if recentSuccessRates.count > 50 {
            recentSuccessRates.removeFirst()
        }
        
        updatePerformanceMetrics()
    }
    
    private func recordFailedTransfer() {
        recentSuccessRates.append(false)
        
        if recentSuccessRates.count > 50 {
            recentSuccessRates.removeFirst()
        }
        
        updatePerformanceMetrics()
    }
    
    private func updatePerformanceMetrics() {
        // Calculate average latency
        if !recentLatencies.isEmpty {
            latency = recentLatencies.reduce(0, +) / Double(recentLatencies.count)
        }
        
        // Calculate success rate
        if !recentSuccessRates.isEmpty {
            let successCount = recentSuccessRates.filter { $0 }.count
            reliabilityScore = Double(successCount) / Double(recentSuccessRates.count)
        }
        
        // Update sync quality based on metrics
        updateSyncQuality()
    }
    
    private func updateSyncQuality() {
        if latency < 100 && reliabilityScore > 0.95 {
            syncQuality = .excellent
        } else if latency < 500 && reliabilityScore > 0.85 {
            syncQuality = .good
        } else if latency < 1000 && reliabilityScore > 0.70 {
            syncQuality = .fair
        } else {
            syncQuality = .poor
        }
    }
    
    private func assessConnectionQuality() {
        let session = WCSession.default
        
        if !session.isPaired {
            connectionState = .disconnected
        } else if !session.isWatchAppInstalled {
            connectionState = .error("Watch app not installed")
        } else if !session.isReachable {
            connectionState = .disconnected
        } else if syncQuality == .poor {
            connectionState = .degraded
        } else {
            connectionState = .connected
        }
        
        // Process queued messages if connection is good
        if connectionState == .connected && !messageQueue.isEmpty {
            processQueuedMessages()
        }
    }
    
    private func processQueuedMessages() {
        let messagesToProcess = messageQueue.sorted { $0.priority.rawValue < $1.priority.rawValue }
        messageQueue.removeAll()
        queuedMessages = 0
        
        Task {
            for message in messagesToProcess {
                _ = await sendMessageWithEnhancedRetry(message)
                // Small delay between messages to avoid overwhelming
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }
    }
    
    // MARK: - Enhanced API Methods
    
    func sendCriticalWorkoutCommand(_ command: [String: Any]) async -> Bool {
        return await sendMessage(command, priority: .critical)
    }
    
    func sendLiveMetrics(_ metrics: [String: Any]) async -> Bool {
        return await sendMessage(metrics, priority: .high)
    }
    
    func sendSessionData(_ data: [String: Any]) async -> Bool {
        return await sendMessage(data, priority: .normal)
    }
    
    func sendBackgroundSync(_ data: [String: Any]) async -> Bool {
        return await sendMessage(data, priority: .low)
    }
    
    // MARK: - Diagnostics
    
    func getConnectionDiagnostics() -> [String: Any] {
        return [
            "connectionState": connectionState.description,
            "syncQuality": syncQuality,
            "latency": latency,
            "reliabilityScore": reliabilityScore,
            "successfulTransfers": successfulTransfers,
            "failedTransfers": failedTransfers,
            "queuedMessages": queuedMessages,
            "transferRate": dataTransferRate
        ]
    }
    
    // MARK: - Timeout Helper
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw ConnectivityError.timeout
            }
            
            guard let result = try await group.next() else {
                throw ConnectivityError.timeout
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - WCSessionDelegate

extension EnhancedConnectivityManager: WCSessionDelegate {
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                self.connectionState = .error(error.localizedDescription)
            } else {
                self.assessConnectionQuality()
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.assessConnectionQuality()
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            // Record incoming message
            self.activeConnections += 1
            
            // Process message and send reply
            replyHandler(["status": "received", "timestamp": Date().timeIntervalSince1970])
            
            self.activeConnections -= 1
        }
    }
    
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            self.connectionState = .disconnected
        }
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            self.connectionState = .disconnected
        }
    }
    #endif
}

// MARK: - Supporting Types

// ConnectivityError is now defined in ConnectivityError.swift

import Foundation
import SwiftUI
import Combine
import os.log
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

// MARK: - App Health Monitor
// Comprehensive monitoring and diagnostics for app health

@MainActor
class AppHealthMonitor: ObservableObject {
    static let shared = AppHealthMonitor()
    
    @Published var healthStatus: AppHealthStatus = .unknown
    @Published var criticalIssues: [HealthIssue] = []
    @Published var warnings: [HealthIssue] = []
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "AppHealthMonitor")
    private var cancellables = Set<AnyCancellable>()
    private var healthCheckTimer: Timer?
    
    enum AppHealthStatus {
        case unknown
        case healthy
        case warning
        case critical
        case error
        
        var color: Color {
            switch self {
            case .unknown: return .gray
            case .healthy: return .green
            case .warning: return .orange
            case .critical: return .red
            case .error: return .red
            }
        }
        
        var description: String {
            switch self {
            case .unknown: return "Unknown"
            case .healthy: return "Healthy"
            case .warning: return "Warning"
            case .critical: return "Critical"
            case .error: return "Error"
            }
        }
    }
    
    struct HealthIssue: Identifiable {
        let id = UUID()
        let category: Category
        let severity: Severity
        let message: String
        let timestamp: Date
        let context: String?
        
        enum Category: CustomStringConvertible {
            case memory
            case connectivity
            case dataValidation
            case performance
            case crash
            case timeout
            case ui
            case authentication
            
            var description: String {
                switch self {
                case .memory: return "Memory"
                case .connectivity: return "Connectivity"
                case .dataValidation: return "Data Validation"
                case .performance: return "Performance"
                case .crash: return "Crash"
                case .timeout: return "Timeout"
                case .ui: return "UI"
                case .authentication: return "Authentication"
                }
            }
        }
        
        enum Severity {
            case info
            case warning
            case critical
            case error
        }
    }
    
    struct PerformanceMetrics {
        var memoryUsage: Double = 0.0
        var cpuUsage: Double = 0.0
        var networkLatency: TimeInterval = 0.0
        var crashCount: Int = 0
        var errorCount: Int = 0
        var lastUpdateTime: Date = Date()
    }
    
    private init() {
        startHealthMonitoring()
    }
    
    // MARK: - Health Monitoring
    
    private func startHealthMonitoring() {
        // Start periodic health checks
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                await self.performHealthCheck()
            }
        }
        
        // Monitor for critical notifications
        NotificationCenter.default.publisher(for: .errorBoundaryTriggered)
            .sink { [weak self] notification in
                if let error = notification.object as? Error,
                   let context = notification.userInfo?["context"] as? String {
                    self?.reportIssue(.ui, .error, error.localizedDescription, context: context)
                }
            }
            .store(in: &cancellables)
    }
    
    func performHealthCheck() async {
        logger.info("🏥 Performing comprehensive health check")
        
        // Clear previous issues
        criticalIssues.removeAll()
        warnings.removeAll()
        
        // Check memory usage
        await checkMemoryHealth()
        
        // Check connectivity
        await checkConnectivityHealth()
        
        // Check data validation
        await checkDataValidationHealth()
        
        // Check authentication
        await checkAuthenticationHealth()
        
        // Update overall health status
        updateOverallHealthStatus()
        
        // Update performance metrics
        updatePerformanceMetrics()
        
        logger.info("🏥 Health check completed: \(self.healthStatus.description)")
    }
    
    // MARK: - Specific Health Checks
    
    private func checkMemoryHealth() async {
        var memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let memoryUsageMB = Double(memoryInfo.resident_size) / 1024.0 / 1024.0
            performanceMetrics.memoryUsage = memoryUsageMB
            
            if memoryUsageMB > 150.0 {
                reportIssue(.memory, .critical, "High memory usage: \(Int(memoryUsageMB))MB")
            } else if memoryUsageMB > 100.0 {
                reportIssue(.memory, .warning, "Elevated memory usage: \(Int(memoryUsageMB))MB")
            }
        }
    }
    
    private func checkConnectivityHealth() async {
        // Check WatchConnectivity status
        #if canImport(WatchConnectivity)
        
        if WCSession.isSupported() {
            let session = WCSession.default
            if !session.isReachable && session.activationState == .activated {
                reportIssue(.connectivity, .warning, "Watch not reachable")
            }
        }
        #endif
    }
    
    private func checkDataValidationHealth() async {
        // Check UserDefaults integrity
        let onboardingCompleted = UserDefaults.standard.bool(forKey: "onboardingCompleted")
        let userLevel = UserDefaults.standard.string(forKey: "userLevel")
        
        if onboardingCompleted && (userLevel?.isEmpty ?? true) {
            reportIssue(.dataValidation, .critical, "Onboarding completed but user level missing")
        }
    }
    
    private func checkAuthenticationHealth() async {
        let authManager = AuthenticationManager.shared
        if authManager.isLoading {
            // Check if loading state has been stuck
            reportIssue(.authentication, .warning, "Authentication in loading state")
        }
    }
    
    // MARK: - Issue Reporting
    
    func reportIssue(_ category: HealthIssue.Category, _ severity: HealthIssue.Severity, _ message: String, context: String? = nil) {
        let issue = HealthIssue(
            category: category,
            severity: severity,
            message: message,
            timestamp: Date(),
            context: context
        )
        
        switch severity {
        case .critical, .error:
            criticalIssues.append(issue)
            performanceMetrics.errorCount += 1
        case .warning:
            warnings.append(issue)
        case .info:
            break
        }
        
        logger.log(level: severity == .critical ? .error : .info, "🏥 Health Issue [\(category)]: \(message)")
    }
    
    private func updateOverallHealthStatus() {
        if !criticalIssues.isEmpty {
            healthStatus = .critical
        } else if !warnings.isEmpty {
            healthStatus = .warning
        } else {
            healthStatus = .healthy
        }
    }
    
    private func updatePerformanceMetrics() {
        performanceMetrics.lastUpdateTime = Date()
    }
    
    // MARK: - Recovery Actions
    
    func performRecoveryActions() {
        logger.info("🔧 Performing recovery actions")
        
        // Clear error states
        criticalIssues.removeAll()
        warnings.removeAll()
        
        // Reset authentication if stuck
        let authManager = AuthenticationManager.shared
        if authManager.isLoading {
            authManager.isLoading = false
        }
        
        // Clear progressive loading state
        ProgressiveLoadingManager.shared.resetProgress()
        
        // Force garbage collection
        // Note: Swift doesn't have explicit GC, but we can clear caches
        URLCache.shared.removeAllCachedResponses()
        
        healthStatus = .healthy
        logger.info("✅ Recovery actions completed")
    }
    
    deinit {
        healthCheckTimer?.invalidate()
    }
}

// MARK: - Health Status View

struct AppHealthStatusView: View {
    @StateObject private var healthMonitor = AppHealthMonitor.shared
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Health Status Header
            HStack {
                Circle()
                    .fill(healthMonitor.healthStatus.color)
                    .frame(width: 12, height: 12)
                
                Text("App Health: \(healthMonitor.healthStatus.description)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showDetails.toggle()
                }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if showDetails {
                // Performance Metrics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Metrics")
                        .font(.subheadline.bold())
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Memory: \(Int(healthMonitor.performanceMetrics.memoryUsage))MB")
                        Spacer()
                        Text("Errors: \(healthMonitor.performanceMetrics.errorCount)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                // Critical Issues
                if !healthMonitor.criticalIssues.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Critical Issues")
                            .font(.subheadline.bold())
                            .foregroundColor(.red)
                        
                        ForEach(healthMonitor.criticalIssues) { issue in
                            Text("• \(issue.message)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Warnings
                if !healthMonitor.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Warnings")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)
                        
                        ForEach(healthMonitor.warnings) { issue in
                            Text("• \(issue.message)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                // Recovery Button
                if healthMonitor.healthStatus != .healthy {
                    Button("Perform Recovery") {
                        healthMonitor.performRecoveryActions()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            Task {
                await healthMonitor.performHealthCheck()
            }
        }
    }
}

#Preview {
    AppHealthStatusView()
        .padding()
}

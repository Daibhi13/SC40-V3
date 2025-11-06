import Foundation
import HealthKit
import CoreLocation
import WatchKit
import Combine

/// Comprehensive testing and validation framework for autonomous workout systems
/// Provides real-time monitoring, data validation, and performance metrics
class WorkoutTestingFramework: ObservableObject {
    static let shared = WorkoutTestingFramework()
    
    // MARK: - Published Properties
    @Published var isTestingActive = false
    @Published var testResults: [TestResult] = []
    @Published var currentTestSession: TestSession?
    @Published var realTimeMetrics: RealTimeTestMetrics = RealTimeTestMetrics()
    
    // MARK: - Test Managers
    private let workoutManager = WatchWorkoutManager.shared
    private let gpsManager = WatchGPSManager.shared
    private let intervalManager = WatchIntervalManager.shared
    private let dataStore = WatchDataStore.shared
    private let syncManager = WatchWorkoutSyncManager.shared
    
    // MARK: - Test Configuration
    private var testConfig: TestConfiguration = TestConfiguration()
    private var testStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupTestMonitoring()
    }
    
    // MARK: - Test Session Management
    
    func startTestSession(_ type: TestType, config: TestConfiguration? = nil) {
        print("🧪 Starting test session: \(type.rawValue)")
        
        if let config = config {
            self.testConfig = config
        }
        
        currentTestSession = TestSession(
            id: UUID(),
            type: type,
            startTime: Date(),
            config: testConfig
        )
        
        testStartTime = Date()
        isTestingActive = true
        testResults.removeAll()
        
        // Start monitoring based on test type
        switch type {
        case .fullAutonomousWorkout:
            startFullWorkoutTest()
        case .gpsAccuracy:
            startGPSAccuracyTest()
        case .healthKitIntegration:
            startHealthKitTest()
        case .batteryPerformance:
            startBatteryTest()
        case .syncReliability:
            startSyncTest()
        case .systemIntegration:
            startSystemIntegrationTest()
        }
        
        setupRealTimeMonitoring()
    }
    
    func endTestSession() {
        print("🧪 Ending test session")
        
        isTestingActive = false
        
        if let session = currentTestSession {
            session.endTime = Date()
            session.results = testResults
            
            // Generate comprehensive test report
            generateTestReport(session)
        }
        
        currentTestSession = nil
        testStartTime = nil
        cancellables.removeAll()
    }
    
    // MARK: - Specific Test Implementations
    
    private func startFullWorkoutTest() {
        print("🏃‍♂️ Starting full autonomous workout test")
        
        // Test all systems integration
        addTestResult(TestResult(
            category: .systemStartup,
            test: "Autonomous Systems Initialization",
            status: .running,
            timestamp: Date(),
            details: "Testing HealthKit, GPS, Interval Manager startup"
        ))
        
        // Monitor system startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.validateSystemStartup()
        }
    }
    
    private func startGPSAccuracyTest() {
        print("📍 Starting GPS accuracy test")
        
        addTestResult(TestResult(
            category: .gpsAccuracy,
            test: "GPS Signal Acquisition",
            status: .running,
            timestamp: Date(),
            details: "Testing GPS signal strength and accuracy"
        ))
        
        // Monitor GPS accuracy over time
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isTestingActive else {
                timer.invalidate()
                return
            }
            self.validateGPSAccuracy()
        }
    }
    
    private func startHealthKitTest() {
        print("❤️ Starting HealthKit integration test")
        
        addTestResult(TestResult(
            category: .healthKit,
            test: "HealthKit Permissions",
            status: .running,
            timestamp: Date(),
            details: "Verifying HealthKit authorization status"
        ))
        
        validateHealthKitPermissions()
    }
    
    private func startBatteryTest() {
        print("🔋 Starting battery performance test")
        
        let initialBatteryLevel = WKInterfaceDevice.current().batteryLevel
        
        addTestResult(TestResult(
            category: .batteryPerformance,
            test: "Initial Battery Level",
            status: .passed,
            timestamp: Date(),
            details: "Battery: \(Int(initialBatteryLevel * 100))%",
            metrics: ["battery_level": Double(initialBatteryLevel)]
        ))
        
        // Monitor battery drain every minute
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isTestingActive else {
                timer.invalidate()
                return
            }
            self.monitorBatteryDrain()
        }
    }
    
    private func startSyncTest() {
        print("🔄 Starting sync reliability test")
        
        addTestResult(TestResult(
            category: .syncReliability,
            test: "Phone Connectivity",
            status: .running,
            timestamp: Date(),
            details: "Testing WatchConnectivity session status"
        ))
        
        validateSyncConnectivity()
    }
    
    private func startSystemIntegrationTest() {
        print("⚙️ Starting system integration test")
        
        // Test all systems working together
        startFullWorkoutTest()
        startGPSAccuracyTest()
        startHealthKitTest()
    }
    
    // MARK: - Real-Time Monitoring
    
    private func setupRealTimeMonitoring() {
        // Monitor workout manager
        workoutManager.$currentHeartRate
            .sink { [weak self] heartRate in
                self?.realTimeMetrics.currentHeartRate = heartRate
            }
            .store(in: &cancellables)
        
        workoutManager.$isWorkoutActive
            .sink { [weak self] isActive in
                self?.realTimeMetrics.isWorkoutActive = isActive
            }
            .store(in: &cancellables)
        
        // Monitor GPS manager
        gpsManager.$currentSpeed
            .sink { [weak self] speed in
                self?.realTimeMetrics.currentSpeed = speed
            }
            .store(in: &cancellables)
        
        gpsManager.$gpsAccuracy
            .sink { [weak self] accuracy in
                self?.realTimeMetrics.gpsAccuracy = accuracy
            }
            .store(in: &cancellables)
        
        // Monitor interval manager
        intervalManager.$currentPhase
            .sink { [weak self] phase in
                self?.realTimeMetrics.currentPhase = phase.rawValue
            }
            .store(in: &cancellables)
        
        intervalManager.$isActive
            .sink { [weak self] isActive in
                self?.realTimeMetrics.isIntervalActive = isActive
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    
    private func validateSystemStartup() {
        var allSystemsReady = true
        var details: [String] = []
        
        // Check HealthKit
        if !workoutManager.isWorkoutActive {
            details.append("❌ HealthKit workout not started")
            allSystemsReady = false
        } else {
            details.append("✅ HealthKit workout active")
        }
        
        // Check GPS
        if !gpsManager.isTracking {
            details.append("❌ GPS tracking not active")
            allSystemsReady = false
        } else {
            details.append("✅ GPS tracking active")
        }
        
        // Check Interval Manager
        if !intervalManager.isActive {
            details.append("❌ Interval manager not active")
            allSystemsReady = false
        } else {
            details.append("✅ Interval manager active")
        }
        
        addTestResult(TestResult(
            category: .systemStartup,
            test: "System Integration Check",
            status: allSystemsReady ? .passed : .failed,
            timestamp: Date(),
            details: details.joined(separator: "\n")
        ))
    }
    
    private func validateGPSAccuracy() {
        let accuracy = gpsManager.gpsAccuracy
        let speed = gpsManager.currentSpeed
        
        var status: TestStatus = .passed
        var details = "GPS Accuracy: \(String(format: "%.1f", accuracy))m"
        
        if accuracy > 10 {
            status = .warning
            details += " (Poor accuracy)"
        } else if accuracy > 5 {
            status = .warning
            details += " (Fair accuracy)"
        } else {
            details += " (Good accuracy)"
        }
        
        details += ", Speed: \(String(format: "%.1f", speed)) mph"
        
        addTestResult(TestResult(
            category: .gpsAccuracy,
            test: "GPS Reading",
            status: status,
            timestamp: Date(),
            details: details,
            metrics: [
                "accuracy": accuracy,
                "speed": speed
            ]
        ))
    }
    
    private func validateHealthKitPermissions() {
        // Check HealthKit authorization
        let healthStore = HKHealthStore()
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let workoutType = HKObjectType.workoutType()
        
        let heartRateAuth = healthStore.authorizationStatus(for: heartRateType)
        let workoutAuth = healthStore.authorizationStatus(for: workoutType)
        
        var status: TestStatus = .passed
        var details: [String] = []
        
        switch heartRateAuth {
        case .sharingAuthorized:
            details.append("✅ Heart Rate: Authorized")
        case .sharingDenied:
            details.append("❌ Heart Rate: Denied")
            status = .failed
        case .notDetermined:
            details.append("⚠️ Heart Rate: Not Determined")
            status = .warning
        @unknown default:
            details.append("❓ Heart Rate: Unknown")
            status = .warning
        }
        
        switch workoutAuth {
        case .sharingAuthorized:
            details.append("✅ Workouts: Authorized")
        case .sharingDenied:
            details.append("❌ Workouts: Denied")
            status = .failed
        case .notDetermined:
            details.append("⚠️ Workouts: Not Determined")
            status = .warning
        @unknown default:
            details.append("❓ Workouts: Unknown")
            status = .warning
        }
        
        addTestResult(TestResult(
            category: .healthKit,
            test: "HealthKit Authorization",
            status: status,
            timestamp: Date(),
            details: details.joined(separator: "\n")
        ))
    }
    
    private func monitorBatteryDrain() {
        let currentBatteryLevel = WKInterfaceDevice.current().batteryLevel
        let timeElapsed = Date().timeIntervalSince(testStartTime ?? Date())
        let drainRate = (1.0 - Double(currentBatteryLevel)) / (timeElapsed / 3600.0) // % per hour
        
        var status: TestStatus = .passed
        if drainRate > 20 {
            status = .warning
        } else if drainRate > 30 {
            status = .failed
        }
        
        addTestResult(TestResult(
            category: .batteryPerformance,
            test: "Battery Drain Rate",
            status: status,
            timestamp: Date(),
            details: "Battery: \(Int(currentBatteryLevel * 100))%, Drain: \(String(format: "%.1f", drainRate))%/hr",
            metrics: [
                "battery_level": Double(currentBatteryLevel),
                "drain_rate": drainRate,
                "time_elapsed": timeElapsed
            ]
        ))
    }
    
    private func validateSyncConnectivity() {
        let isConnected = syncManager.isPhoneConnected
        let queueStatus = dataStore.syncQueueCount
        
        addTestResult(TestResult(
            category: .syncReliability,
            test: "Sync Status Check",
            status: isConnected ? .passed : .warning,
            timestamp: Date(),
            details: "Phone Connected: \(isConnected ? "Yes" : "No"), Queue: \(queueStatus) items",
            metrics: [
                "is_connected": isConnected ? 1.0 : 0.0,
                "queue_count": Double(queueStatus)
            ]
        ))
    }
    
    // MARK: - Test Result Management
    
    private func addTestResult(_ result: TestResult) {
        DispatchQueue.main.async {
            self.testResults.append(result)
        }
    }
    
    private func setupTestMonitoring() {
        // Monitor for system errors or warnings
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WorkoutSystemError"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let error = notification.object as? Error {
                self?.addTestResult(TestResult(
                    category: .systemError,
                    test: "System Error Detected",
                    status: .failed,
                    timestamp: Date(),
                    details: error.localizedDescription
                ))
            }
        }
    }
    
    // MARK: - Report Generation
    
    private func generateTestReport(_ session: TestSession) {
        let report = TestReport(
            session: session,
            summary: generateTestSummary(),
            recommendations: generateRecommendations()
        )
        
        // Save report to data store
        saveTestReport(report)
        
        print("📊 Test report generated: \(report.summary.totalTests) tests, \(report.summary.passedTests) passed")
    }
    
    private func generateTestSummary() -> TestSummary {
        let totalTests = testResults.count
        let passedTests = testResults.filter { $0.status == .passed }.count
        let failedTests = testResults.filter { $0.status == .failed }.count
        let warningTests = testResults.filter { $0.status == .warning }.count
        
        return TestSummary(
            totalTests: totalTests,
            passedTests: passedTests,
            failedTests: failedTests,
            warningTests: warningTests,
            successRate: totalTests > 0 ? Double(passedTests) / Double(totalTests) : 0.0
        )
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        // Analyze test results and generate recommendations
        let failedResults = testResults.filter { $0.status == .failed }
        let warningResults = testResults.filter { $0.status == .warning }
        
        if !failedResults.isEmpty {
            recommendations.append("🔴 Critical Issues Found: \(failedResults.count) tests failed")
            for result in failedResults {
                recommendations.append("  • \(result.test): \(result.details)")
            }
        }
        
        if !warningResults.isEmpty {
            recommendations.append("🟡 Performance Warnings: \(warningResults.count) tests need attention")
        }
        
        // GPS-specific recommendations
        let gpsTests = testResults.filter { $0.category == .gpsAccuracy }
        if let avgAccuracy = gpsTests.compactMap({ $0.metrics?["accuracy"] }).average() {
            if avgAccuracy > 10 {
                recommendations.append("📍 GPS Recommendation: Consider testing in open area for better accuracy")
            }
        }
        
        // Battery recommendations
        let batteryTests = testResults.filter { $0.category == .batteryPerformance }
        if let drainRate = batteryTests.last?.metrics?["drain_rate"], drainRate > 20 {
            recommendations.append("🔋 Battery Recommendation: High drain rate detected, consider optimizing background processes")
        }
        
        return recommendations
    }
    
    private func saveTestReport(_ report: TestReport) {
        // Save to UserDefaults for now, could be enhanced to Core Data
        if let data = try? JSONEncoder().encode(report) {
            UserDefaults.standard.set(data, forKey: "LastTestReport_\(report.session.id)")
        }
    }
    
    // MARK: - Public Interface
    
    func getTestHistory() -> [TestReport] {
        // Load saved test reports
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        let reportKeys = keys.filter { $0.hasPrefix("LastTestReport_") }
        
        return reportKeys.compactMap { key in
            guard let data = UserDefaults.standard.data(forKey: key),
                  let report = try? JSONDecoder().decode(TestReport.self, from: data) else {
                return nil
            }
            return report
        }.sorted { $0.session.startTime > $1.session.startTime }
    }
    
    func clearTestHistory() {
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        let reportKeys = keys.filter { $0.hasPrefix("LastTestReport_") }
        
        for key in reportKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

// MARK: - Supporting Data Models

enum TestType: String, CaseIterable {
    case fullAutonomousWorkout = "Full Autonomous Workout"
    case gpsAccuracy = "GPS Accuracy"
    case healthKitIntegration = "HealthKit Integration"
    case batteryPerformance = "Battery Performance"
    case syncReliability = "Sync Reliability"
    case systemIntegration = "System Integration"
}

enum TestCategory: String, Codable {
    case systemStartup = "System Startup"
    case gpsAccuracy = "GPS Accuracy"
    case healthKit = "HealthKit"
    case batteryPerformance = "Battery Performance"
    case syncReliability = "Sync Reliability"
    case systemError = "System Error"
}

enum TestStatus: String, Codable {
    case running = "Running"
    case passed = "Passed"
    case failed = "Failed"
    case warning = "Warning"
}

struct TestConfiguration {
    var testDuration: TimeInterval = 300 // 5 minutes default
    var gpsAccuracyThreshold: Double = 5.0 // meters
    var batteryDrainThreshold: Double = 20.0 // % per hour
    var heartRateMonitoring: Bool = true
    var verboseLogging: Bool = true
}

struct TestResult: Codable, Identifiable {
    let id: UUID
    let category: TestCategory
    let test: String
    let status: TestStatus
    let timestamp: Date
    let details: String
    let metrics: [String: Double]?
    
    init(category: TestCategory, test: String, status: TestStatus, timestamp: Date, details: String, metrics: [String: Double]? = nil) {
        self.id = UUID()
        self.category = category
        self.test = test
        self.status = status
        self.timestamp = timestamp
        self.details = details
        self.metrics = metrics
    }
}

class TestSession: ObservableObject {
    let id: UUID
    let type: TestType
    let startTime: Date
    var endTime: Date?
    let config: TestConfiguration
    var results: [TestResult] = []
    
    init(id: UUID, type: TestType, startTime: Date, config: TestConfiguration) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.config = config
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let typeRawValue = try container.decode(String.self, forKey: .type)
        let type = TestType(rawValue: typeRawValue) ?? .fullAutonomousWorkout
        let startTime = try container.decode(Date.self, forKey: .startTime)
        let config = TestConfiguration() // Use default config for decoded sessions
        
        self.init(id: id, type: type, startTime: startTime, config: config)
        
        self.endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        self.results = try container.decode([TestResult].self, forKey: .results)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, startTime, endTime, config, results
    }
}

struct RealTimeTestMetrics {
    var currentHeartRate: Int = 0
    var isWorkoutActive: Bool = false
    var currentSpeed: Double = 0.0
    var gpsAccuracy: CLLocationAccuracy = 0
    var currentPhase: String = "Unknown"
    var isIntervalActive: Bool = false
}

struct TestSummary: Codable {
    let totalTests: Int
    let passedTests: Int
    let failedTests: Int
    let warningTests: Int
    let successRate: Double
}

struct TestReport: Codable {
    let session: TestSession
    let summary: TestSummary
    let recommendations: [String]
}

// MARK: - Extensions

extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}

extension TestSession: Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(results, forKey: .results)
    }
}

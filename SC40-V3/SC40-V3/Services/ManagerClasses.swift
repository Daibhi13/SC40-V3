import Foundation
import SwiftUI
import WatchConnectivity
import Combine

// MARK: - Core Manager Classes for iPhone App

// MARK: - Watch Connectivity Manager
@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isWatchConnected = false
    @Published var isWatchAppInstalled = false
    @Published var lastSyncDate: Date?
    @Published var isSyncing = false
    @Published var isWatchReachable = false
    @Published var syncProgress: Double = 0.0
    
    private var session: WCSession?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func checkWatchStatus() -> String {
        if isSyncing {
            return "Syncing..."
        } else if isWatchConnected {
            return isWatchAppInstalled ? "Connected" : "App Not Installed"
        } else {
            return "Not Connected"
        }
    }
    
    func sendWorkoutData(_ data: [String: Any]) {
        guard let session = session, session.isReachable else { return }
        
        session.sendMessage(data, replyHandler: nil) { error in
            print("Failed to send workout data: \(error.localizedDescription)")
        }
    }
    
    func syncSessionData(_ sessionData: CompletedSession) {
        let data: [String: Any] = [
            "sessionId": sessionData.id.uuidString,
            "sessionName": sessionData.sessionName,
            "date": sessionData.date.timeIntervalSince1970,
            "duration": sessionData.duration,
            "reps": sessionData.completedReps.count
        ]
        sendWorkoutData(data)
    }
    
    func launchWorkoutOnWatch(session: TrainingSession) async {
        guard let wcSession = self.session, wcSession.isReachable else { return }
        
        isSyncing = true
        syncProgress = 0.0
        
        let workoutData: [String: Any] = [
            "action": "launchWorkout",
            "sessionType": session.type,
            "week": session.week,
            "day": session.day
        ]
        
        wcSession.sendMessage(workoutData, replyHandler: { response in
            DispatchQueue.main.async {
                self.isSyncing = false
                self.syncProgress = 1.0
            }
        }) { error in
            DispatchQueue.main.async {
                self.isSyncing = false
                print("Failed to launch workout on watch: \(error.localizedDescription)")
            }
        }
    }
    
    func syncCurrentWeekSessions(_ sessions: [CompletedSession]) async {
        // Sync current week sessions to watch
        for session in sessions {
            syncSessionData(session)
        }
    }
    
    func syncNextSessionBatch(_ sessions: [CompletedSession]) async {
        // Sync next batch of sessions to watch
        for session in sessions {
            syncSessionData(session)
        }
    }
    
    func sendMessage(_ message: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let session = session, session.isReachable else {
            completion(false)
            return
        }
        
        session.sendMessage(message, replyHandler: { _ in
            completion(true)
        }) { error in
            completion(false)
        }
    }
    
    @Published var trainingSessionsSynced = false
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = activationState == .activated
            self.isWatchReachable = session.isReachable
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
            self.isWatchReachable = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
            self.isWatchReachable = false
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle messages from Watch
        print("Received message from Watch: \(message)")
    }
}

// MARK: - User Profile Manager
@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var currentProfile: UserProfile?
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "user_profile"
    
    init() {
        loadProfile()
    }
    
    func loadProfile() {
        isLoading = true
        
        if let data = userDefaults.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            currentProfile = profile
        } else {
            currentProfile = createDefaultProfile()
        }
        
        isLoading = false
    }
    
    func saveProfile(_ profile: UserProfile) {
        currentProfile = profile
        
        if let data = try? JSONEncoder().encode(profile) {
            userDefaults.set(data, forKey: profileKey)
        }
    }
    
    private func createDefaultProfile() -> UserProfile {
        var profile = UserProfile(
            name: "Sprint Coach User",
            email: nil,
            gender: "Male",
            age: 25,
            height: 70.0, // inches
            weight: 180.0, // pounds
            personalBests: [:],
            level: "Beginner",
            baselineTime: 6.0, // seconds for 40-yard dash
            frequency: 3 // 3 days per week
        )
        profile.goals = ["Improve 40-yard dash time"]
        profile.personalBest40Yard = nil
        return profile
    }
}

// MARK: - Authentication Manager
@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    enum AuthProvider {
        case apple
        case google
        case facebook
        case instagram
        case email
    }
    
    struct User: Codable {
        let id: String
        let email: String
        let name: String
        let provider: String
    }
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        // Simulate authentication check
        isAuthenticated = UserDefaults.standard.bool(forKey: "is_authenticated")
    }
    
    func authenticate(with provider: AuthProvider) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate authentication process
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            self.isAuthenticated = true
            self.currentUser = User(
                id: UUID().uuidString,
                email: "user@example.com",
                name: "Sprint Coach User",
                provider: "\(provider)"
            )
            UserDefaults.standard.set(true, forKey: "is_authenticated")
        } catch {
            self.errorMessage = "Authentication failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signIn(with provider: AuthProvider) {
        isLoading = true
        
        // Simulate sign-in process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isAuthenticated = true
            self.currentUser = User(
                id: UUID().uuidString,
                email: "user@example.com",
                name: "Sprint Coach User",
                provider: "\(provider)"
            )
            UserDefaults.standard.set(true, forKey: "is_authenticated")
            self.isLoading = false
        }
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        UserDefaults.standard.set(false, forKey: "is_authenticated")
    }
}

// MARK: - GPS Manager
@MainActor
class GPSManager: NSObject, ObservableObject {
    @Published var currentSpeed: Double = 0.0
    @Published var currentLocation: CLLocation?
    @Published var isTracking = false
    @Published var accuracy: Double = 0.0
    
    private let locationManager = CLLocationManager()
    private var startLocation: CLLocation?
    private var startTime: Date?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startTracking() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        
        isTracking = true
        startTime = Date()
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        startLocation = nil
        startTime = nil
    }
    
    func calculateSprintResult(distance: Double) -> SprintResult? {
        guard let startTime = startTime,
              let startLocation = startLocation,
              let currentLocation = currentLocation else { return nil }
        
        let time = Date().timeIntervalSince(startTime)
        let actualDistance = currentLocation.distance(from: startLocation)
        
        return SprintResult(
            distance: distance,
            time: time,
            date: Date(),
            gpsAccuracy: currentLocation.horizontalAccuracy
        )
    }
}

extension GPSManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        accuracy = location.horizontalAccuracy
        
        if startLocation == nil {
            startLocation = location
        }
        
        if let startLoc = startLocation {
            let distance = location.distance(from: startLoc)
            let timeInterval = location.timestamp.timeIntervalSince(startLoc.timestamp)
            
            if timeInterval > 0 {
                currentSpeed = distance / timeInterval // m/s
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPS Error: \(error.localizedDescription)")
    }
}

// MARK: - Workout Sync Manager
@MainActor
class WorkoutSyncManager: ObservableObject {
    static let shared = WorkoutSyncManager()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncStatus: SyncStatus = .idle
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
    }
    
    private let watchConnectivity = WatchConnectivityManager.shared
    
    func syncWorkoutData(_ session: CompletedSession) {
        isSyncing = true
        syncStatus = .syncing
        
        // Simulate sync process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.watchConnectivity.syncSessionData(session)
            self.lastSyncDate = Date()
            self.syncStatus = .success
            self.isSyncing = false
        }
    }
    
    func forceSyncAll() {
        isSyncing = true
        syncStatus = .syncing
        
        // Simulate full sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.lastSyncDate = Date()
            self.syncStatus = .success
            self.isSyncing = false
        }
    }
}

// MARK: - Premium Connectivity Manager
@MainActor
class PremiumConnectivityManager: ObservableObject {
    static let shared = PremiumConnectivityManager()
    
    @Published var isPremiumUser = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var premiumFeatures: [PremiumFeature] = []
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastSyncTime: Date?
    @Published var pendingOperations: Int = 0
    @Published var connectionQuality: ConnectionQuality = .good
    @Published var dataFreshness: DataFreshness = .current
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(ConnectivityError)
    }
    
    enum ConnectionState: Equatable {
        case connected
        case disconnected
        case connecting
        case error(String)
        
        var displayText: String {
            switch self {
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting..."
            case .error(let message):
                return message.isEmpty ? "Connection Error" : "Error: \(message)"
            }
        }
    }
    
    enum ConnectionQuality {
        case excellent
        case good
        case poor
        case unknown
    }
    
    enum DataFreshness: Equatable {
        case current
        case stale
        case outdated
        
        var displayText: String {
            switch self {
            case .current: return "Up to date"
            case .stale: return "Data may be outdated"
            case .outdated: return "Sync required"
            }
        }
    }
    
    struct PremiumFeature {
        let id: String
        let name: String
        let description: String
        let isEnabled: Bool
    }
    
    init() {
        loadPremiumStatus()
        setupPremiumFeatures()
    }
    
    private func loadPremiumStatus() {
        isPremiumUser = UserDefaults.standard.bool(forKey: "is_premium_user")
    }
    
    private func setupPremiumFeatures() {
        premiumFeatures = [
            PremiumFeature(id: "advanced_analytics", name: "Advanced Analytics", description: "Detailed performance analysis", isEnabled: isPremiumUser),
            PremiumFeature(id: "custom_programs", name: "Custom Programs", description: "Personalized training programs", isEnabled: isPremiumUser),
            PremiumFeature(id: "watch_sync", name: "Watch Sync", description: "Real-time Apple Watch synchronization", isEnabled: isPremiumUser)
        ]
    }
    
    func upgradeToPremium() {
        isPremiumUser = true
        UserDefaults.standard.set(true, forKey: "is_premium_user")
        setupPremiumFeatures()
    }
}

// MARK: - App Startup Manager
@MainActor
class AppStartupManager: ObservableObject {
    static let shared = AppStartupManager()
    
    @Published var isInitialized = false
    @Published var startupProgress: Double = 0.0
    @Published var currentTask = "Initializing..."
    @Published var startupPhase: StartupPhase = .initializing
    @Published var syncProgress: Double = 0.0
    @Published var syncMessage: String = ""
    @Published var syncError: String?
    @Published var canProceedToMainView = false
    
    enum StartupPhase {
        case initializing
        case syncBuffer
        case syncError
        case ready
    }
    
    func initializeApp() async {
        do {
            currentTask = "Loading user profile..."
            startupProgress = 0.2
            try await Task.sleep(nanoseconds: 500_000_000)
            
            currentTask = "Setting up connectivity..."
            startupProgress = 0.4
            try await Task.sleep(nanoseconds: 500_000_000)
            
            currentTask = "Loading session data..."
            startupProgress = 0.6
            try await Task.sleep(nanoseconds: 500_000_000)
            
            currentTask = "Finalizing setup..."
            startupProgress = 0.8
            try await Task.sleep(nanoseconds: 500_000_000)
            
            currentTask = "Ready!"
            startupProgress = 1.0
            isInitialized = true
        } catch {
            // Handle task cancellation or other errors
            startupPhase = .syncError
            syncError = (error as? CancellationError) != nil ? "Initialization cancelled" : error.localizedDescription
            isInitialized = false
        }
    }
}

// MARK: - Training Synchronization Manager
@MainActor
class TrainingSynchronizationManager: ObservableObject {
    static let shared = TrainingSynchronizationManager()
    
    @Published var isSyncing = false
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    
    func syncTrainingData() async {
        isSyncing = true
        syncProgress = 0.0
        
        do {
            // Simulate sync process
            for i in 1...10 {
                try await Task.sleep(nanoseconds: 200_000_000)
                syncProgress = Double(i) / 10.0
            }
            
            lastSyncDate = Date()
        } catch {
            // Handle task cancellation or other errors
            // If cancelled, leave progress as-is; optionally set an error state if you add one later
            print("Training sync interrupted: \(error)")
        }
        
        isSyncing = false
    }
}

import CoreLocation


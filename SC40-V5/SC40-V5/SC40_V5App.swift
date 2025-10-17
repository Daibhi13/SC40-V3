//
//  SC40_V5App.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import SwiftUI
import UserNotifications
import Combine

@main
struct SC40_V5App: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var contentManager = ContentManager.shared
    @StateObject private var notificationService = NotificationService.shared

    init() {
        // Configure app appearance
        configureAppAppearance()

        // Setup services
        setupServices()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app content
                if appState.isFirstLaunch {
                    EntryIOSView()
                } else if !appState.isAuthenticated {
                    WelcomeView()
                } else {
                    ContentView()
                }
            }
            .environmentObject(appState)
            .environmentObject(contentManager)
            .environmentObject(notificationService)
            .onAppear {
                // Request notification permissions on first launch
                if appState.isFirstLaunch {
                    requestNotificationPermissions()
                }
            }
        }
    }

    // MARK: - App Configuration

    private func configureAppAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.primary)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppColors.darkBackground)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(AppColors.primary)

        // Set global tint color
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(AppColors.primary)
    }

    private func setupServices() {
        // Initialize core services
        _ = HealthKitService.shared
        _ = WatchSessionManager.shared
        _ = AudioCueManager.shared

        // Setup notification categories
        notificationService.setupNotificationCategories()
    }

    private func requestNotificationPermissions() {
        Task {
            do {
                let granted = try await notificationService.requestAuthorization()
                if granted {
                    // Schedule welcome notification
                    try await notificationService.scheduleMotivationalNotification()
                }
            } catch {
                print("Notification permission request failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - App State Management

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isFirstLaunch: Bool = true
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserProfile?
    @Published var currentSession: TrainingSession?
    @Published var networkStatus: NetworkStatus = .unknown

    enum NetworkStatus {
        case unknown
        case connected
        case disconnected
    }

    init() {
        checkFirstLaunch()
        checkAuthentication()
    }

    private func checkFirstLaunch() {
        isFirstLaunch = !UserDefaults.standard.bool(forKey: UserDefaultsKeys.firstLaunch)
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.firstLaunch)
        }
    }

    private func checkAuthentication() {
        // Check if user is authenticated
        if let userId = UserDefaults.standard.string(forKey: "userId"),
           !userId.isEmpty {
            isAuthenticated = true

            // Load user profile
            currentUser = DataUtils.loadFromUserDefaults(UserProfile.self, forKey: UserDefaultsKeys.userProfile)
        }
    }

    func authenticate(user: UserProfile) {
        currentUser = user
        isAuthenticated = true

        // Save authentication state
        UserDefaults.standard.set(user.id.uuidString, forKey: "userId")
        DataUtils.saveToUserDefaults(user, forKey: UserDefaultsKeys.userProfile)
    }

    func logout() {
        currentUser = nil
        isAuthenticated = false

        // Clear authentication data
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.userProfile)
    }
}

// MARK: - Preview

struct SC40_V5App_Previews: PreviewProvider {
    static var previews: some View {
        // For preview purposes, show the main content view
        ContentView()
            .environmentObject(AppState.shared)
            .environmentObject(ContentManager.shared)
            .environmentObject(NotificationService.shared)
    }
}

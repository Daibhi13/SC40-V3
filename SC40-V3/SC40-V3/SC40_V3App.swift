import SwiftUI

@main
struct SC40_V3App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Initialize synchronization manager at app launch
    @StateObject private var syncManager = TrainingSynchronizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            EntryIOSView()
                .environmentObject(syncManager)
        }
    }
}

import SwiftUI

@main
struct SC40_V3App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            EntryIOSView()
        }
    }
}

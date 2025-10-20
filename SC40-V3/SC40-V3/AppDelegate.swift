#if canImport(UIKit)
import UIKit
#endif

import SwiftUI

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FacebookCore)
import FacebookCore
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

#if canImport(UIKit)
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure Firebase
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        print("🔥 Firebase configured")
        #endif
        
        // Configure Facebook SDK
        #if canImport(FacebookCore)
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        print("📘 Facebook SDK configured")
        #endif
        
        // Configure Google Sign-In
        #if canImport(GoogleSignIn)
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["CLIENT_ID"] as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
            print("🔍 Google Sign-In configured")
        }
        #endif
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // Handle Facebook URL
        #if canImport(FacebookCore)
        // iOS 26.0+ compatible URL handling
        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String
        let annotation = options[UIApplication.OpenURLOptionsKey.annotation]
        
        if ApplicationDelegate.shared.application(app, open: url, sourceApplication: sourceApplication, annotation: annotation) {
            return true
        }
        #endif
        
        // Handle Google Sign-In URL
        #if canImport(GoogleSignIn)
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        #endif
        
        return false
    }
}
#else
// Fallback for non-iOS platforms
class AppDelegate: NSObject {
    static func configureApp() {
        print("⚠️ AppDelegate not available on this platform")
    }
}
#endif

// MARK: - SwiftUI App Integration
#if canImport(UIKit)
extension AppDelegate {
    static func configureAppSDKs() {
        // This method can be called from SwiftUI App if needed
        let delegate = AppDelegate()
        _ = delegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
    }
}
#endif

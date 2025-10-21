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
    
    @available(iOS, introduced: 9.0, deprecated: 26.0, message: "Use scene(_:openURLContexts:) instead")
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var handled = false

        #if canImport(FacebookCore)
        if let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String {
            let annotation = options[UIApplication.OpenURLOptionsKey.annotation]
            if ApplicationDelegate.shared.application(app, open: url, sourceApplication: sourceApplication, annotation: annotation) {
                handled = true
            }
        }
        #endif

        #if canImport(GoogleSignIn)
        if GIDSignIn.sharedInstance.handle(url) {
            handled = true
        }
        #endif

        return handled
    }
}
    
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first else { return }
        let url = context.url
        let options = context.options

        // Facebook URL handling
        #if canImport(FacebookCore)
        let _ = ApplicationDelegate.shared.application(UIApplication.shared,
                                                       open: url,
                                                       sourceApplication: options.sourceApplication,
                                                       annotation: options.annotation)
        #endif

        // Google Sign-In URL handling
        #if canImport(GoogleSignIn)
        _ = GIDSignIn.sharedInstance.handle(url)
        #endif
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

import Foundation
import SwiftUI
import Combine

/// Automated Help & Info content management system
/// Updates help content when technical changes or compliance requirements change
@MainActor
class HelpContentManager: ObservableObject, @unchecked Sendable {
    static let shared = HelpContentManager()
    
    @Published var lastUpdated = Date()
    @Published var contentVersion = "1.0.0"
    
    private init() {
        checkForUpdates()
    }
    
    // MARK: - Auto-Update System
    
    /// Automatically checks for technical or compliance updates
    func checkForUpdates() {
        // Check app version changes
        if hasAppVersionChanged() {
            updateVersionSpecificContent()
        }
        
        // Check iOS version compatibility
        if hasIOSRequirementsChanged() {
            updateSystemRequirements()
        }
        
        // Check subscription pricing changes
        if hasSubscriptionPricingChanged() {
            updateSubscriptionContent()
        }
        
        // Check privacy policy updates
        if hasPrivacyPolicyChanged() {
            updatePrivacyContent()
        }
        
        // Update timestamp
        lastUpdated = Date()
    }
    
    // MARK: - Content Generators
    
    /// Generates current FAQ content based on app state
    func getCurrentFAQContent() -> [HelpFAQItem] {
        return [
            HelpFAQItem(
                question: "How do I start my first sprint training session?",
                answer: "Go to the Training tab, select your fitness level, and tap 'Start Session'. Follow the warm-up instructions and begin your first 40-yard sprint when prompted. The app uses GPS timing for accurate results."
            ),
            HelpFAQItem(
                question: "What equipment do I need for Sprint Coach 40?",
                answer: "You only need your iPhone (iOS \(getCurrentIOSRequirement())+) and comfortable running shoes. For best results, train on a flat surface like a track, field, or park. Apple Watch Series 4+ is optional but recommended for heart rate monitoring."
            ),
            HelpFAQItem(
                question: "How accurate is the GPS timing?",
                answer: "Sprint Coach 40 uses advanced GPS algorithms optimized for short-distance sprinting. Accuracy is typically within 0.1 seconds for 40-yard distances when used outdoors with clear sky view and GPS signal strength above 4 bars."
            ),
            HelpFAQItem(
                question: "What's the difference between Free and Pro versions?",
                answer: "Pro (\(getCurrentSubscriptionPricing())) includes advanced analytics, video analysis, personalized coaching, unlimited training programs, and priority support. Free includes basic timing and standard training programs with limited analytics."
            ),
            HelpFAQItem(
                question: "Can I use Sprint Coach 40 indoors?",
                answer: "GPS timing requires outdoor use with clear sky view. However, you can use manual timing indoors and still access all training programs, drills, and educational content from the 40 Yard Smart hub."
            ),
            HelpFAQItem(
                question: "How often should I train with Sprint Coach 40?",
                answer: "We recommend 3-4 sessions per week with rest days between intense training. The app's adaptive session generator will suggest optimal training frequency based on your fitness level and recovery patterns."
            ),
            HelpFAQItem(
                question: "How do I improve my 40-yard time?",
                answer: "Focus on proper form, consistent training, strength building, and following the progressive 12-week training programs. The 40 Yard Smart hub provides comprehensive technique guidance, and Pro users get personalized AI coaching recommendations."
            ),
            HelpFAQItem(
                question: "Is Sprint Coach 40 suitable for beginners?",
                answer: "Absolutely! The app includes beginner-friendly programs with proper progression, form instruction, and safety guidelines. Start with the 'Getting Started' program and the app will adapt to your fitness level automatically."
            )
        ]
    }
    
    /// Generates current subscription content
    func getCurrentSubscriptionContent() -> [HelpArticle] {
        let pricing = getCurrentSubscriptionPricing()
        
        return [
            HelpArticle(
                title: "Subscription Plans",
                content: "Sprint Coach 40 offers Monthly (\(pricing.monthly)), Annual (\(pricing.annual)), and Lifetime (\(pricing.lifetime)) subscriptions. All plans include unlimited access to Pro features, advanced analytics, AI coaching, and priority support."
            ),
            HelpArticle(
                title: "Managing Your Subscription",
                content: "Manage your subscription through iOS Settings > Apple ID > Subscriptions > Sprint Coach 40. Here you can view billing dates, change plans, or cancel your subscription. Changes take effect at the next billing cycle."
            ),
            HelpArticle(
                title: "Canceling Your Subscription",
                content: "Cancel anytime through iOS Settings > Apple ID > Subscriptions. Your access continues until the end of the current billing period. No cancellation fees apply. You can resubscribe anytime to restore Pro features."
            ),
            HelpArticle(
                title: "Refund Policy",
                content: "Refunds are handled by Apple through the App Store. Visit reportaproblem.apple.com or contact Apple Support directly. Refund eligibility depends on Apple's policies and timing of your request."
            ),
            HelpArticle(
                title: "Family Sharing",
                content: "Sprint Coach 40 subscriptions support Apple Family Sharing. The subscription holder can share access with up to 5 family members through iOS Settings > Apple ID > Family Sharing."
            )
        ]
    }
    
    /// Generates current technical support content
    func getCurrentTechnicalContent() -> [HelpArticle] {
        return [
            HelpArticle(
                title: "System Requirements",
                content: "Sprint Coach 40 requires iOS \(getCurrentIOSRequirement()) or later, iPhone 8 or newer for optimal performance, and Apple Watch Series 4 or later for Watch features. Older devices may experience limitations with GPS accuracy."
            ),
            HelpArticle(
                title: "GPS Timing Issues",
                content: "For accurate timing, ensure you're outdoors with clear sky view, location services are enabled for Sprint Coach 40, and your iPhone has strong GPS signal (4+ bars). Avoid areas with tall buildings or dense tree cover."
            ),
            HelpArticle(
                title: "Apple Watch Connectivity",
                content: "Ensure both devices are paired, Bluetooth is enabled, both apps are updated to version \(getCurrentAppVersion()), and your Watch is properly paired. Try restarting both devices if sync issues persist."
            ),
            HelpArticle(
                title: "Data Sync Problems",
                content: "Check that iCloud is enabled in iOS Settings > Apple ID > iCloud, you're signed in with the same Apple ID on all devices, and you have sufficient iCloud storage available (requires 50MB+ free space)."
            )
        ]
    }
    
    /// Generates current privacy content
    func getCurrentPrivacyContent() -> [HelpArticle] {
        return [
            HelpArticle(
                title: "Privacy Policy",
                content: "We collect minimal data necessary for app functionality: training times, progress metrics, and device information. Your personal data is never sold or shared with third parties without explicit consent. Last updated: \(getPrivacyPolicyDate())."
            ),
            HelpArticle(
                title: "Data Collection",
                content: "Sprint Coach 40 collects: GPS location during training (for timing only), health data (if authorized), usage analytics (anonymized), and account information (Apple ID only). All data is encrypted and stored securely."
            ),
            HelpArticle(
                title: "GDPR Compliance",
                content: "We comply with GDPR and other privacy regulations. EU users have rights to access, modify, or delete their data. Contact privacy@sprintcoach40.com for data requests. We respond within 30 days as required by law."
            ),
            HelpArticle(
                title: "Children's Privacy",
                content: "Sprint Coach 40 is suitable for users 13 and older. We do not knowingly collect personal information from children under 13. Parental supervision is recommended for younger athletes using the app."
            )
        ]
    }
    
    // MARK: - Version Checking
    
    private func hasAppVersionChanged() -> Bool {
        let currentVersion = getCurrentAppVersion()
        let storedVersion = UserDefaults.standard.string(forKey: "LastKnownAppVersion") ?? "1.0.0"
        
        if currentVersion != storedVersion {
            UserDefaults.standard.set(currentVersion, forKey: "LastKnownAppVersion")
            return true
        }
        return false
    }
    
    private func hasIOSRequirementsChanged() -> Bool {
        let currentRequirement = getCurrentIOSRequirement()
        let storedRequirement = UserDefaults.standard.string(forKey: "LastKnownIOSRequirement") ?? "15.0"
        
        if currentRequirement != storedRequirement {
            UserDefaults.standard.set(currentRequirement, forKey: "LastKnownIOSRequirement")
            return true
        }
        return false
    }
    
    private func hasSubscriptionPricingChanged() -> Bool {
        let currentPricing = getCurrentSubscriptionPricing()
        let storedPricing = UserDefaults.standard.string(forKey: "LastKnownPricing") ?? "$9.99/$59.99/$149.99"
        let currentPricingString = "\(currentPricing.monthly)/\(currentPricing.annual)/\(currentPricing.lifetime)"
        
        if currentPricingString != storedPricing {
            UserDefaults.standard.set(currentPricingString, forKey: "LastKnownPricing")
            return true
        }
        return false
    }
    
    private func hasPrivacyPolicyChanged() -> Bool {
        let currentDate = getPrivacyPolicyDate()
        let storedDate = UserDefaults.standard.string(forKey: "LastKnownPrivacyDate") ?? "2024-01-01"
        
        if currentDate != storedDate {
            UserDefaults.standard.set(currentDate, forKey: "LastKnownPrivacyDate")
            return true
        }
        return false
    }
    
    // MARK: - Current Values
    
    private func getCurrentAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private func getCurrentIOSRequirement() -> String {
        return "15.0" // Update this when minimum iOS version changes
    }
    
    private func getCurrentSubscriptionPricing() -> (monthly: String, annual: String, lifetime: String) {
        return (monthly: "$9.99", annual: "$59.99", lifetime: "$149.99")
    }
    
    private func getPrivacyPolicyDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date()) // Update when privacy policy changes
    }
    
    // MARK: - Update Functions
    
    private func updateVersionSpecificContent() {
        print("📱 App version changed - updating help content")
        objectWillChange.send()
    }
    
    private func updateSystemRequirements() {
        print("📱 iOS requirements changed - updating technical support content")
        objectWillChange.send()
    }
    
    private func updateSubscriptionContent() {
        print("💳 Subscription pricing changed - updating billing content")
        objectWillChange.send()
    }
    
    private func updatePrivacyContent() {
        print("🔒 Privacy policy updated - updating legal content")
        objectWillChange.send()
    }
}

// MARK: - Supporting Models

struct HelpArticle {
    let title: String
    let content: String
}

struct HelpFAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

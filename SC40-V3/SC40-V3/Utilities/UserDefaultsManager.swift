import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private init() {}
    
    // PERFORMANCE: Disabled verbose logging - set DEBUG_LOGGING to true to re-enable
    private static let DEBUG_LOGGING = false
    
    // CRASH FIX: Make all operations synchronous and thread-safe
    func setValue<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
        if Self.DEBUG_LOGGING {
            print("💾 [USERDEFAULTS] [SET]: \(key) = \(value)")
        }
    }
    
    func getValue<T>(forKey key: String, defaultValue: T) -> T {
        let value = UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        if Self.DEBUG_LOGGING {
            print("📖 [USERDEFAULTS] [GET]: \(key) = \(value)")
        }
        return value
    }
    
    func getBool(forKey key: String) -> Bool {
        let value = UserDefaults.standard.bool(forKey: key)
        if Self.DEBUG_LOGGING {
            print("📖 [USERDEFAULTS] [GET]: \(key) = \(value)")
        }
        return value
    }
    
    func getString(forKey key: String) -> String? {
        let value = UserDefaults.standard.string(forKey: key)
        if Self.DEBUG_LOGGING {
            print("📖 [USERDEFAULTS] [GET]: \(key) = \(value ?? "nil")")
        }
        return value
    }
    
    func removeValue(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
        if Self.DEBUG_LOGGING {
            print("🗑️ [USERDEFAULTS] [REMOVE]: \(key)")
        }
    }
    
    func synchronize() {
        UserDefaults.standard.synchronize()
        if Self.DEBUG_LOGGING {
            print("🔄 [USERDEFAULTS] [SYNC]: Synchronized")
        }
    }
}

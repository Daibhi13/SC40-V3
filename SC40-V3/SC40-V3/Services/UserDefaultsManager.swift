import Foundation

// MARK: - User Defaults Manager
class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    func setValue(_ value: Any?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func getValue(forKey key: String) -> Any? {
        return userDefaults.object(forKey: key)
    }
    
    func getString(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
    
    func getBool(forKey key: String) -> Bool {
        return userDefaults.bool(forKey: key)
    }
    
    func getDouble(forKey key: String) -> Double {
        return userDefaults.double(forKey: key)
    }
    
    func getDate(forKey key: String) -> Date? {
        return userDefaults.object(forKey: key) as? Date
    }
    
    func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    func synchronize() {
        userDefaults.synchronize()
    }
}

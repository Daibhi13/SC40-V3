import Foundation

// Import required models
// TrainingSession is defined in Models/SprintSetAndTrainingSession.swift
// UserSessionPreferences is defined in Models/SessionLibrary.swift
// UnifiedSessionGenerator is defined in Services/UnifiedSessionGenerator.swift

/// Lazy session generator that creates sessions on-demand to prevent memory spikes
/// Generates sessions incrementally (week by week) instead of all at once
class LazySessionGenerator {
    static let shared = LazySessionGenerator()
    
    // Cache for generated sessions
    private var sessionCache: [String: [TrainingSession]] = [:]
    private let cacheQueue = DispatchQueue(label: "com.sc40.sessionCache", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Lazy Generation
    
    /// Generate sessions for a specific week only (lazy loading)
    func generateWeekSessions(
        week: Int,
        userLevel: String,
        frequency: Int,
        userPreferences: UserSessionPreferences? = nil
    ) -> [TrainingSession] {
        
        let cacheKey = "\(userLevel)-\(frequency)-W\(week)"
        
        // Check cache first
        if let cached = getCachedSessions(key: cacheKey) {
            print("📦 LazySessionGenerator: Using cached sessions for Week \(week)")
            return cached
        }
        
        // Generate only this week's sessions
        print("🔄 LazySessionGenerator: Generating Week \(week) sessions")
        print("   Level: \(userLevel), Frequency: \(frequency) days/week")
        
        var weekSessions: [TrainingSession] = []
        
        for day in 1...frequency {
            let session = UnifiedSessionGenerator.shared.generateDeterministicSession(
                week: week,
                day: day,
                userLevel: userLevel,
                frequency: frequency
            )
            weekSessions.append(session)
        }
        
        print("✅ LazySessionGenerator: Generated \(weekSessions.count) sessions for Week \(week)")
        
        // Cache the result
        cacheSessions(key: cacheKey, sessions: weekSessions)
        
        return weekSessions
    }
    
    /// Generate sessions for current week + next week (2-week lookahead)
    func generateCurrentAndNextWeek(
        currentWeek: Int,
        userLevel: String,
        frequency: Int,
        userPreferences: UserSessionPreferences? = nil
    ) -> [TrainingSession] {
        
        print("🔄 LazySessionGenerator: Generating 2-week lookahead (W\(currentWeek) + W\(currentWeek + 1))")
        
        var sessions: [TrainingSession] = []
        
        // Generate current week
        let currentWeekSessions = generateWeekSessions(
            week: currentWeek,
            userLevel: userLevel,
            frequency: frequency,
            userPreferences: userPreferences
        )
        sessions.append(contentsOf: currentWeekSessions)
        
        // Generate next week if not at end of program
        if currentWeek < 12 {
            let nextWeekSessions = generateWeekSessions(
                week: currentWeek + 1,
                userLevel: userLevel,
                frequency: frequency,
                userPreferences: userPreferences
            )
            sessions.append(contentsOf: nextWeekSessions)
        }
        
        print("✅ LazySessionGenerator: Generated \(sessions.count) sessions (2-week lookahead)")
        
        return sessions
    }
    
    /// Pre-generate sessions in background (incremental, non-blocking)
    func preGenerateInBackground(
        userLevel: String,
        frequency: Int,
        startWeek: Int = 1,
        endWeek: Int = 12,
        userPreferences: UserSessionPreferences? = nil,
        completion: (() -> Void)? = nil
    ) {
        
        print("🔄 LazySessionGenerator: Starting background pre-generation")
        print("   Weeks: \(startWeek) to \(endWeek)")
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            for week in startWeek...endWeek {
                // Generate week sessions (will use cache if already generated)
                _ = self.generateWeekSessions(
                    week: week,
                    userLevel: userLevel,
                    frequency: frequency,
                    userPreferences: userPreferences
                )
                
                // Small delay between weeks to prevent memory spike
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            print("✅ LazySessionGenerator: Background pre-generation complete")
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    // MARK: - Cache Management
    
    private func getCachedSessions(key: String) -> [TrainingSession]? {
        return cacheQueue.sync {
            return sessionCache[key]
        }
    }
    
    private func cacheSessions(key: String, sessions: [TrainingSession]) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.sessionCache[key] = sessions
        }
    }
    
    /// Clear cache for specific user profile
    func clearCache(userLevel: String? = nil, frequency: Int? = nil) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            if let level = userLevel, let freq = frequency {
                // Clear specific profile cache
                let keysToRemove = self?.sessionCache.keys.filter { key in
                    key.hasPrefix("\(level)-\(freq)-")
                }
                keysToRemove?.forEach { self?.sessionCache.removeValue(forKey: $0) }
                print("🧹 LazySessionGenerator: Cleared cache for \(level) \(freq)-day")
            } else {
                // Clear all cache
                self?.sessionCache.removeAll()
                print("🧹 LazySessionGenerator: Cleared all cache")
            }
        }
    }
    
    /// Get cache statistics
    func getCacheStats() -> (totalWeeks: Int, totalSessions: Int) {
        return cacheQueue.sync {
            let totalWeeks = sessionCache.count
            let totalSessions = sessionCache.values.reduce(0) { $0 + $1.count }
            return (totalWeeks, totalSessions)
        }
    }
}

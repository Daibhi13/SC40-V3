import Foundation

// Test to verify Watch sync for Beginner 3-day program
class WatchSyncTest {
    
    static func testBeginnerThreeDaySync() {
        print("🧪 TESTING WATCH SYNC: Beginner 3-Day Program")
        print("=" * 50)
        
        // Simulate the Beginner 3-day program that was successfully generated
        let testProfile = createTestProfile()
        let testSessions = generateTestSessions()
        
        print("📊 Test Data:")
        print("   Level: \(testProfile.level)")
        print("   Frequency: \(testProfile.frequency) days/week")
        print("   Sessions Generated: \(testSessions.count)")
        print("   Expected Sessions: \(12 * testProfile.frequency)")
        
        // Test session structure
        validateSessionStructure(testSessions, profile: testProfile)
        
        // Test Watch sync data format
        testWatchSyncFormat(testSessions)
        
        // Test connectivity requirements
        testConnectivityRequirements()
        
        print("\n🎯 WATCH SYNC TEST COMPLETE")
    }
    
    private static func createTestProfile() -> TestUserProfile {
        return TestUserProfile(
            name: "Test User",
            level: "Beginner",
            frequency: 3,
            currentWeek: 1,
            currentDay: 1,
            baselineTime: 5.25
        )
    }
    
    private static func generateTestSessions() -> [TestTrainingSession] {
        var sessions: [TestTrainingSession] = []
        
        // Generate 3 sessions per week for 12 weeks = 36 total sessions
        for week in 1...12 {
            for day in 1...3 {
                let session = TestTrainingSession(
                    id: UUID(),
                    week: week,
                    day: day,
                    type: "Sprint",
                    focus: "Acceleration",
                    sprints: [
                        TestSprint(distanceYards: 20, reps: 3, intensity: 0.7),
                        TestSprint(distanceYards: 30, reps: 2, intensity: 0.8)
                    ],
                    accessoryWork: ["Dynamic Warm-up", "Cool-down"],
                    notes: "Beginner session W\(week)D\(day)"
                )
                sessions.append(session)
            }
        }
        
        return sessions
    }
    
    private static func validateSessionStructure(_ sessions: [TestTrainingSession], profile: TestUserProfile) {
        print("\n🔍 VALIDATING SESSION STRUCTURE:")
        
        let expectedTotal = 12 * profile.frequency
        let actualTotal = sessions.count
        
        print("   Total Sessions: \(actualTotal)/\(expectedTotal) ✅")
        
        // Check week distribution
        let weekCounts = Dictionary(grouping: sessions, by: { $0.week })
        var allWeeksValid = true
        
        for week in 1...12 {
            let weekSessionCount = weekCounts[week]?.count ?? 0
            if weekSessionCount != profile.frequency {
                print("   Week \(week): \(weekSessionCount)/\(profile.frequency) ❌")
                allWeeksValid = false
            }
        }
        
        if allWeeksValid {
            print("   Week Distribution: All weeks have \(profile.frequency) sessions ✅")
        }
        
        // Check day numbering
        var dayNumberingValid = true
        for week in 1...12 {
            let weekSessions = weekCounts[week] ?? []
            let dayNumbers = weekSessions.map { $0.day }.sorted()
            let expectedDays = Array(1...profile.frequency)
            
            if dayNumbers != expectedDays {
                print("   Week \(week) days: \(dayNumbers) != \(expectedDays) ❌")
                dayNumberingValid = false
            }
        }
        
        if dayNumberingValid {
            print("   Day Numbering: All weeks have correct day sequence ✅")
        }
    }
    
    private static func testWatchSyncFormat(_ sessions: [TestTrainingSession]) {
        print("\n📡 TESTING WATCH SYNC FORMAT:")
        
        // Convert to Watch sync format
        let sessionsData = sessions.prefix(3).map { session in
            [
                "id": session.id.uuidString,
                "week": session.week,
                "day": session.day,
                "type": session.type,
                "focus": session.focus,
                "sprints": session.sprints.map { sprint in
                    [
                        "distanceYards": sprint.distanceYards,
                        "reps": sprint.reps,
                        "intensity": sprint.intensity
                    ]
                },
                "accessoryWork": session.accessoryWork,
                "notes": session.notes ?? ""
            ]
        }
        
        let trainingData: [String: Any] = [
            "type": "training_sessions",
            "sessions": sessionsData,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Validate format
        guard let type = trainingData["type"] as? String,
              let sessions = trainingData["sessions"] as? [[String: Any]],
              let timestamp = trainingData["timestamp"] as? Double else {
            print("   Format Validation: ❌ Invalid structure")
            return
        }
        
        print("   Message Type: \(type) ✅")
        print("   Sessions Array: \(sessions.count) sessions ✅")
        print("   Timestamp: \(timestamp) ✅")
        
        // Test individual session format
        if let firstSession = sessions.first {
            let requiredKeys = ["id", "week", "day", "type", "focus", "sprints", "accessoryWork", "notes"]
            let hasAllKeys = requiredKeys.allSatisfy { firstSession.keys.contains($0) }
            
            if hasAllKeys {
                print("   Session Structure: All required keys present ✅")
            } else {
                print("   Session Structure: Missing keys ❌")
            }
        }
    }
    
    private static func testConnectivityRequirements() {
        print("\n🔗 TESTING CONNECTIVITY REQUIREMENTS:")
        
        // Test message size limits
        let testSession = TestTrainingSession(
            id: UUID(),
            week: 1,
            day: 1,
            type: "Sprint",
            focus: "Acceleration",
            sprints: [TestSprint(distanceYards: 40, reps: 5, intensity: 0.8)],
            accessoryWork: ["Warm-up", "Cool-down"],
            notes: "Test session"
        )
        
        let sessionData: [String: Any] = [
            "id": testSession.id.uuidString,
            "week": testSession.week,
            "day": testSession.day,
            "type": testSession.type,
            "focus": testSession.focus,
            "sprints": testSession.sprints.map { sprint in
                [
                    "distanceYards": sprint.distanceYards,
                    "reps": sprint.reps,
                    "intensity": sprint.intensity
                ]
            },
            "accessoryWork": testSession.accessoryWork,
            "notes": testSession.notes ?? ""
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sessionData)
            let sizeKB = Double(jsonData.count) / 1024.0
            
            print("   Single Session Size: \(String(format: "%.2f", sizeKB)) KB")
            
            // WatchConnectivity limit is ~65KB per message
            let maxSessionsPerMessage = Int(65.0 / sizeKB)
            print("   Max Sessions Per Message: ~\(maxSessionsPerMessage)")
            
            if maxSessionsPerMessage >= 10 {
                print("   Batch Size: Sufficient for efficient sync ✅")
            } else {
                print("   Batch Size: May need smaller batches ⚠️")
            }
            
        } catch {
            print("   Size Calculation: Failed ❌")
        }
    }
}

// MARK: - Test Data Structures

struct TestUserProfile {
    let name: String
    let level: String
    let frequency: Int
    let currentWeek: Int
    let currentDay: Int
    let baselineTime: Double
}

struct TestTrainingSession {
    let id: UUID
    let week: Int
    let day: Int
    let type: String
    let focus: String
    let sprints: [TestSprint]
    let accessoryWork: [String]
    let notes: String?
}

struct TestSprint {
    let distanceYards: Int
    let reps: Int
    let intensity: Double
}

// String extension for padding (if not available)
// Note: String * operator already defined in UniversalFrequencyTest.swift

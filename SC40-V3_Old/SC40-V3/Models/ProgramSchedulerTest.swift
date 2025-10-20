import Foundation

// MARK: - Program Scheduler Test & Demo

/// Test function to demonstrate program generation and export functionality
func testProgramScheduler() {
    print("=== SC40 Program Scheduler Test ===\n")
    
    // Test 1: Generate a basic program
    print("1. Generating 12-week Beginner program (3 days/week)...")
    let beginnerProgram = generateScheduledProgram(
        level: "Beginner",
        daysPerWeek: 3,
        weeks: 12,
        userId: "test_user_001"
    )
    
    print("✅ Generated program with \(beginnerProgram.schedule.count) sessions")
    print("   Level: \(beginnerProgram.level)")
    print("   Duration: \(beginnerProgram.weeks) weeks, \(beginnerProgram.daysPerWeek) days/week")
    print("   Generated: \(beginnerProgram.generatedAtISO)")
    
    // Show first few sessions
    print("\n   First 5 sessions:")
    for session in beginnerProgram.schedule.prefix(5) {
        print("   Week \(session.week), Day \(session.day): \(session.session.name) (\(session.session.focus))")
    }
    
    // Test 2: Generate and export to JSON
    print("\n2. Testing JSON export...")
    do {
        let jsonData = try exportProgramToJSONData(beginnerProgram)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        let lines = jsonString.components(separatedBy: .newlines)
        print("✅ JSON export successful (\(jsonData.count) bytes)")
        print("   First 10 lines of JSON:")
        for line in lines.prefix(10) {
            print("   \(line)")
        }
        print("   ... (truncated)")
    } catch {
        print("❌ JSON export failed: \(error)")
    }
    
    // Test 3: Generate different levels
    print("\n3. Testing different training levels...")
    let levels = ["Beginner", "Intermediate", "Advanced", "Elite"]
    
    for level in levels {
        let program = generateScheduledProgram(level: level, daysPerWeek: 4, weeks: 4)
        let sprintSessions = program.schedule.filter { $0.session.type == "Sprint" }
        let benchmarkSessions = program.schedule.filter { $0.session.type == "Benchmark" }
        
        print("   \(level): \(sprintSessions.count) sprint sessions, \(benchmarkSessions.count) benchmark sessions")
    }
    
    // Test 4: Check time trial placement
    print("\n4. Checking time trial placement in 12-week program...")
    let timeTrials = beginnerProgram.schedule.filter { $0.session.type == "Benchmark" }
    print("   Found \(timeTrials.count) time trial sessions:")
    for tt in timeTrials {
        print("   Week \(tt.week), Day \(tt.day): \(tt.session.name)")
    }
    
    // Test 5: Generate and save to file (demonstrate usage)
    print("\n5. File export demonstration...")
    do {
        let url = try generateAndExportProgram(
            level: "Elite",
            daysPerWeek: 5,
            weeks: 8,
            userId: "demo_user",
            filename: "demo_elite_program.json"
        )
        print("✅ Program saved successfully!")
        print("   File location: \(url.path)")
        
        // Check if file exists
        if FileManager.default.fileExists(atPath: url.path) {
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
            print("   File size: \(fileSize) bytes")
        }
    } catch {
        print("❌ File export failed: \(error)")
    }
    
    print("\n=== Test Complete ===")
}

// MARK: - Quick Usage Examples

/// Quick example showing basic usage patterns
func showUsageExamples() {
    print("\n=== Quick Usage Examples ===\n")
    
    // Example 1: Simple program generation
    print("Example 1: Basic program generation")
    let program = generateScheduledProgram(level: "Intermediate", daysPerWeek: 4, weeks: 12)
    print("Generated \(program.schedule.count) sessions for \(program.level) level")
    
    // Example 2: Export to JSON string
    print("\nExample 2: JSON export")
    do {
        let jsonData = try exportProgramToJSONData(program)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        print("JSON size: \(jsonString.count) characters")
    } catch {
        print("Export error: \(error)")
    }
    
    // Example 3: Save to file
    print("\nExample 3: Save to documents")
    do {
        let url = try generateAndExportProgram(level: "Advanced", daysPerWeek: 6, weeks: 10)
        print("Saved to: \(url.lastPathComponent)")
    } catch {
        print("Save error: \(error)")
    }
}

// MARK: - Program Analysis

/// Analyze session distribution across a program
func analyzeProgram(_ program: ScheduledProgram) {
    print("\n=== Program Analysis ===")
    print("Level: \(program.level)")
    print("Duration: \(program.weeks) weeks × \(program.daysPerWeek) days = \(program.schedule.count) total sessions")
    
    // Count session types
    let sessionTypes = Dictionary(grouping: program.schedule) { $0.session.type }
    print("\nSession Types:")
    for (type, sessions) in sessionTypes.sorted(by: { $0.key < $1.key }) {
        print("  \(type): \(sessions.count) sessions")
    }
    
    // Count focus areas
    let focusAreas = Dictionary(grouping: program.schedule) { $0.session.focus }
    print("\nFocus Areas:")
    for (focus, sessions) in focusAreas.sorted(by: { $0.key < $1.key }) {
        print("  \(focus): \(sessions.count) sessions")
    }
    
    // Distance distribution
    let distances = program.schedule.compactMap { $0.session.sprints.first?.distanceYards }
    let distanceSet = Set(distances)
    print("\nDistance Range: \(distanceSet.min() ?? 0) - \(distanceSet.max() ?? 0) yards")
    print("Unique distances: \(distanceSet.sorted())")
}

#if DEBUG
// Run test when in debug mode
// To use: call testProgramScheduler() from your app or playground
#endif

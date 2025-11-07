import Foundation

// Example user profile for 3 days/week, intermediate
// Moved top-level code into a function for testing/demo
func runExample3DayIntermediate() {
    var _ = UserProfile(
        name: "Sample User",
        email: nil,
        gender: "Other",
        age: 25,
        height: 70,
        weight: 160,
        personalBests: ["40yd": 5.00],
        level: "Intermediate",
        baselineTime: 5.00,
        frequency: 3,
        currentWeek: 1,
        currentDay: 1,
        leaderboardOptIn: true
    )
    // TODO: Implement generateVariedAdaptiveProgram
    // let program = generateVariedAdaptiveProgram(user: &userProfile)
    // for session in program.prefix(9) {
    //     print("Week \(session.week), Day \(session.day):")
    //     print("  Type: \(session.level)")
    //     print("  Sprints: \(session.sprints.map { "\($0.reps)x\($0.distanceYards)yd [\($0.intensity)]" }.joined(separator: ", "))")
    //     print("  Accessory: \(session.accessoryWork.joined(separator: ", "))")
    //     print()
    // }
    print("Example program generation - not yet implemented")
}

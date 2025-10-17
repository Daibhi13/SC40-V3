import Foundation

// Test file to verify types are accessible
let testProfile = UserProfile(
    name: "Test",
    email: nil,
    gender: "Male",
    age: 25,
    height: 180.0,
    weight: nil,
    personalBests: [:],
    level: "Beginner",
    baselineTime: 5.0,
    frequency: 3
)

let testSession = TrainingSession(
    id: UUID(),
    week: 1,
    day: 1,
    type: "Test",
    focus: "Test",
    sprints: [],
    accessoryWork: [],
    notes: nil
)

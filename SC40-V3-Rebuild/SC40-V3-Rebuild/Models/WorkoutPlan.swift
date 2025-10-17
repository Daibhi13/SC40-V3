// 12-week training plan
import Foundation

struct WorkoutPlan: Codable {
    var weeks: [WeekPlan]
}

struct WeekPlan: Codable {
    var weekNumber: Int
    var workouts: [String]
}

import Foundation

struct TimeTrialWorkoutModel {
    let sets: Int
    let restTime: Int // seconds
    let distance: Int = 40 // yards, fixed for 40yd time trial
    
    var repDistances: [Int] { Array(repeating: distance, count: sets) }
    var totalReps: Int { sets }
    var restTimeString: String {
        String(format: "%d:%02d", restTime/60, restTime%60)
    }
}

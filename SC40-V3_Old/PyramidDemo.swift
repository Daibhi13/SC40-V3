import Foundation

/// Demonstration of how a 10, 20, 30, 40, 50 yard pyramid workout would work
/// in the SC40-V3 system

// MARK: - Custom Pyramid Session Example

/// Your requested 10, 20, 30, 40, 50 yard pyramid session
/// This shows exactly how the SC40-V3 system would handle multiple varying distances
let pyramidDemo_10_20_30_40_50 = TrainingSession(
    week: 1,
    day: 1,
    type: "Pyramid Workout",
    focus: "Progressive Distance Build",
    sprints: [
        // Warm-up
        SprintSet(distanceYards: 440, reps: 1, intensity: "Warm-up Jog"),
        SprintSet(distanceYards: 0, reps: 1, intensity: "Dynamic Stretch"),
        
        // Sprint drills  
        SprintSet(distanceYards: 20, reps: 3, intensity: "High Knees"),
        SprintSet(distanceYards: 20, reps: 3, intensity: "A-Skips"),
        
        // Strides
        SprintSet(distanceYards: 20, reps: 4, intensity: "Strides"),
        
        // YOUR PYRAMID: 10, 20, 30, 40, 50 yards
        SprintSet(distanceYards: 10, reps: 1, intensity: "Pyramid Build-Up"),
        SprintSet(distanceYards: 20, reps: 1, intensity: "Pyramid Build-Up"), 
        SprintSet(distanceYards: 30, reps: 1, intensity: "Pyramid Build-Up"),
        SprintSet(distanceYards: 40, reps: 1, intensity: "Pyramid Build-Up"),
        SprintSet(distanceYards: 50, reps: 1, intensity: "Pyramid Peak"),
        
        // Cool-down
        SprintSet(distanceYards: 400, reps: 1, intensity: "Cool Down Jog")
    ],
    accessoryWork: [
        "Foam Roll Quads/Hamstrings",
        "Core Stability 5 min"
    ],
    notes: "Custom pyramid: 10→20→30→40→50 yards progressive build-up. Watch will display each distance individually with GPS tracking."
)

// MARK: - How Distance Array Would Look

func demonstratePyramidDistanceArray() {
    print("=== 10, 20, 30, 40, 50 Yard Pyramid Demo ===")
    print()
    
    // This is what the Watch would receive as the distance array:
    let distanceArray = pyramidDemo_10_20_30_40_50.sprints.flatMap { sprint in
        Array(repeating: sprint.distanceYards, count: sprint.reps)
    }
    
    print("Complete distance array for Watch tracking:")
    print(distanceArray)
    print()
    
    print("Workout progression:")
    for (index, distance) in distanceArray.enumerated() {
        let repNumber = index + 1
        switch distance {
        case 0:
            print("Rep \(repNumber): Timed activity (stretching/rest)")
        case 10, 20, 30, 40, 50:
            if [10, 20, 30, 40, 50].contains(distance) {
                print("Rep \(repNumber): 🏃‍♂️ PYRAMID SPRINT - \(distance) yards")
            } else {
                print("Rep \(repNumber): \(distance) yard drill/stride")
            }
        case 400, 440:
            print("Rep \(repNumber): \(distance) yard jog")
        default:
            print("Rep \(repNumber): \(distance) yard drill/stride")
        }
    }
    
    print()
    print("Total workout distance: \(distanceArray.reduce(0, +)) yards")
    print("Total reps/activities: \(distanceArray.count)")
    
    // Show how the Watch would display distances during the pyramid portion
    print()
    print("=== Watch Display During Pyramid Section ===")
    let pyramidIndices = [5, 6, 7, 8, 9] // Indices for 10,20,30,40,50 yard reps
    for index in pyramidIndices {
        let distance = distanceArray[index]
        print("Rep \(index + 1): Watch displays '\(distance) yd' → GPS tracks \(Double(distance) * 0.9144) meters")
    }
}

// MARK: - Alternative Pyramid Variations

/// If you wanted to do the pyramid up AND down: 10→20→30→40→50→40→30→20→10
let fullPyramid_10_to_50_and_back = TrainingSession(
    week: 1,
    day: 2,
    type: "Full Pyramid",
    focus: "Complete Pyramid Challenge",
    sprints: [
        // Warm-up (abbreviated for example)
        SprintSet(distanceYards: 440, reps: 1, intensity: "Warm-up Jog"),
        SprintSet(distanceYards: 0, reps: 1, intensity: "Dynamic Stretch"),
        
        // FULL PYRAMID: Up and down
        SprintSet(distanceYards: 10, reps: 1, intensity: "Pyramid Up"),
        SprintSet(distanceYards: 20, reps: 1, intensity: "Pyramid Up"), 
        SprintSet(distanceYards: 30, reps: 1, intensity: "Pyramid Up"),
        SprintSet(distanceYards: 40, reps: 1, intensity: "Pyramid Up"),
        SprintSet(distanceYards: 50, reps: 1, intensity: "Pyramid Peak"),
        SprintSet(distanceYards: 40, reps: 1, intensity: "Pyramid Down"),
        SprintSet(distanceYards: 30, reps: 1, intensity: "Pyramid Down"),
        SprintSet(distanceYards: 20, reps: 1, intensity: "Pyramid Down"),
        SprintSet(distanceYards: 10, reps: 1, intensity: "Pyramid Down"),
        
        // Cool-down
        SprintSet(distanceYards: 400, reps: 1, intensity: "Cool Down Jog")
    ],
    accessoryWork: ["Extended recovery protocol"],
    notes: "Full pyramid: 10→20→30→40→50→40→30→20→10 yards. Total: 270 sprint yards."
)

/// Multiple sets of your pyramid
let multiplePyramids_2_sets = TrainingSession(
    week: 1,
    day: 3,
    type: "2x Pyramid Sets",
    focus: "Volume Pyramid Training",
    sprints: [
        // Warm-up
        SprintSet(distanceYards: 440, reps: 1, intensity: "Warm-up Jog"),
        SprintSet(distanceYards: 0, reps: 1, intensity: "Dynamic Stretch"),
        
        // FIRST PYRAMID SET
        SprintSet(distanceYards: 10, reps: 1, intensity: "Pyramid Set 1"),
        SprintSet(distanceYards: 20, reps: 1, intensity: "Pyramid Set 1"), 
        SprintSet(distanceYards: 30, reps: 1, intensity: "Pyramid Set 1"),
        SprintSet(distanceYards: 40, reps: 1, intensity: "Pyramid Set 1"),
        SprintSet(distanceYards: 50, reps: 1, intensity: "Pyramid Set 1"),
        
        // Rest break (represented as timed activity)
        SprintSet(distanceYards: 0, reps: 1, intensity: "Rest Between Sets (3 min)"),
        
        // SECOND PYRAMID SET  
        SprintSet(distanceYards: 10, reps: 1, intensity: "Pyramid Set 2"),
        SprintSet(distanceYards: 20, reps: 1, intensity: "Pyramid Set 2"), 
        SprintSet(distanceYards: 30, reps: 1, intensity: "Pyramid Set 2"),
        SprintSet(distanceYards: 40, reps: 1, intensity: "Pyramid Set 2"),
        SprintSet(distanceYards: 50, reps: 1, intensity: "Pyramid Set 2"),
        
        // Cool-down
        SprintSet(distanceYards: 400, reps: 1, intensity: "Cool Down Jog")
    ],
    accessoryWork: ["Extended warm-up", "Progressive recovery"],
    notes: "2 complete pyramid sets: 10→20→30→40→50 yards each. Total: 300 sprint yards."
)

// MARK: - Implementation Guide

/*
 ## How to Implement Your 10,20,30,40,50 Pyramid in SC40-V3:
 
 ### Method 1: Custom Session Creation
 You can create a custom TrainingSession exactly like the examples above.
 
 ### Method 2: Adding to Session Library
 Add your pyramid to the SessionLibrary.swift file:
 
 ```swift
 SprintSessionTemplate(
     id: 999, 
     name: "Custom 10-20-30-40-50 Pyramid", 
     distance: 50,  // Peak distance
     reps: 5,       // Total pyramid reps
     rest: 120,     // Rest between each distance
     focus: "Progressive Distance Build", 
     level: "Intermediate", 
     sessionType: LibrarySessionType.sprint
 )
 ```
 
 ### Method 3: Watch App Integration
 The WorkoutWatchViewModel will automatically:
 
 1. **Receive distance array**: [440, 0, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 10, 20, 30, 40, 50, 400]
 2. **Display current distance**: Shows "10 yd", "20 yd", "30 yd", "40 yd", "50 yd" during pyramid
 3. **GPS tracking**: Converts to meters (10yd = 9.14m, 20yd = 18.29m, etc.)
 4. **Rest management**: Automatic rest periods between each distance
 5. **Progress tracking**: Shows "Rep 13 of 18" during pyramid section
 
 ### Watch Display Example:
 - Rep 13: "10 yd" → GPS tracks 9.14 meters
 - Rep 14: "20 yd" → GPS tracks 18.29 meters  
 - Rep 15: "30 yd" → GPS tracks 27.43 meters
 - Rep 16: "40 yd" → GPS tracks 36.58 meters
 - Rep 17: "50 yd" → GPS tracks 45.72 meters
 
 The system handles each distance individually with precise GPS tracking and automatic rest periods.
 */

```

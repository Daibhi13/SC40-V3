//
//  TrainingViewModel.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import Foundation
import CoreLocation
import Combine

/// View model for training session management
class TrainingViewModel: NSObject, ObservableObject {
    @Published var isWorkoutActive = false
    @Published var isPaused = false
    @Published var isSprintActive = false
    @Published var currentSession: SprintSetAndTrainingSession?
    @Published var selectedSessionType: SprintSetAndTrainingSession.SessionType?
    @Published var estimatedDuration: TimeInterval = 1800 // 30 minutes default
    @Published var currentSet = 0
    @Published var totalSets = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var sprintTimer: TimeInterval = 0
    @Published var restTimer: TimeInterval = 0
    @Published var workoutProgress: Double = 0
    @Published var currentSprintSet: SprintSetConfiguration?
    @Published var nextSprintSet: SprintSetConfiguration?
    @Published var currentHeartRate: Int = 0
    @Published var currentDistance: Double = 0
    @Published var currentPace: TimeInterval = 0
    @Published var currentLocation: CLLocation?

    private var workoutTimer: Timer?
    private var sprintTimerInstance: Timer?
    private var restTimerInstance: Timer?
    private var locationManager = CLLocationManager()

    override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Setup

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0 // Update every meter
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Workout Control

    func startWorkout() {
        guard let sessionType = selectedSessionType else { return }

        // Create a sample session for demo
        currentSession = createSampleSession(for: sessionType)
        isWorkoutActive = true
        currentSet = 1
        totalSets = currentSession?.sprintSets.count ?? 0

        startWorkoutTimer()
        startNextSet()
    }

    func pauseWorkout() {
        isPaused = true
        workoutTimer?.invalidate()
        sprintTimerInstance?.invalidate()
        restTimerInstance?.invalidate()
    }

    func resumeWorkout() {
        isPaused = false
        startWorkoutTimer()

        if isSprintActive {
            startSprintTimer()
        } else {
            startRestTimer()
        }
    }

    func stopWorkout() {
        isWorkoutActive = false
        isPaused = false
        workoutTimer?.invalidate()
        sprintTimerInstance?.invalidate()
        restTimerInstance?.invalidate()

        // Show completion screen
    }

    func emergencyStop() {
        // Immediate stop for safety
        stopWorkout()
        // Additional emergency handling
    }

    // MARK: - Timer Management

    private func startWorkoutTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
            self?.updateWorkoutProgress()
        }
    }

    private func startNextSet() {
        guard let session = currentSession,
              currentSet <= totalSets else {
            stopWorkout()
            return
        }

        currentSprintSet = session.sprintSets[currentSet - 1]
        startSprintTimer()
    }

    private func startSprintTimer() {
        guard let sprintSet = currentSprintSet else { return }

        isSprintActive = true
        sprintTimer = 0

        sprintTimerInstance = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.sprintTimer += 0.1

            if self?.sprintTimer ?? 0 >= sprintSet.targetTime {
                self?.completeSprint()
            }
        }
    }

    private func startRestTimer() {
        guard let sprintSet = currentSprintSet else { return }

        isSprintActive = false
        restTimer = 0

        restTimerInstance = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.restTimer += 1

            if self?.restTimer ?? 0 >= sprintSet.restBetweenReps {
                self?.startNextSet()
            }
        }
    }

    private func completeSprint() {
        sprintTimerInstance?.invalidate()

        // Record sprint data
        if currentSet < totalSets {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startRestTimer()
            }
        } else {
            stopWorkout()
        }
    }

    private func updateWorkoutProgress() {
        guard let session = currentSession else { return }
        let totalEstimatedTime = estimatedDuration
        workoutProgress = min(elapsedTime / totalEstimatedTime, 1.0)
    }

    // MARK: - Sample Data

    private func createSampleSession(for type: SprintSetAndTrainingSession.SessionType) -> SprintSetAndTrainingSession {
        let sprintSets: [SprintSetConfiguration] = [
            SprintSetConfiguration(
                name: "Warm-up Sprint",
                distance: 60,
                targetTime: 10.0,
                restBetweenReps: 60,
                restBetweenSets: 0,
                repetitions: 1,
                sets: 1,
                progressionType: .constant,
                intensity: .low,
                focus: .acceleration
            ),
            SprintSetConfiguration(
                name: "Main Sprint Set",
                distance: 100,
                targetTime: 15.0,
                restBetweenReps: 90,
                restBetweenSets: 0,
                repetitions: 4,
                sets: 1,
                progressionType: .constant,
                intensity: .high,
                focus: .maximumVelocity
            ),
            SprintSetConfiguration(
                name: "Cool-down Jog",
                distance: 200,
                targetTime: 45.0,
                restBetweenReps: 0,
                restBetweenSets: 0,
                repetitions: 1,
                sets: 1,
                progressionType: .constant,
                intensity: .low,
                focus: .technique
            )
        ]

        return SprintSetAndTrainingSession(
            name: "\(type.rawValue) Session",
            description: "Sample session for \(type.rawValue)",
            sessionType: type,
            difficulty: .intermediate,
            estimatedDuration: 1800,
            sprintSets: sprintSets
        )
    }
}

// MARK: - CLLocationManagerDelegate

extension TrainingViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
        default:
            break
        }
    }
}

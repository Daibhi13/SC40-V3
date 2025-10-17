//
//  WatchSessionManager.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import Foundation
import WatchConnectivity
import Combine

/// Manages communication between iOS app and Apple Watch
class WatchSessionManager: NSObject, ObservableObject {

    static let shared = WatchSessionManager()

    @Published private(set) var isReachable = false
    @Published private(set) var isPaired = false
    @Published private(set) var receivedMessages: [WatchMessage] = []
    @Published private(set) var lastError: Error?

    private let session: WCSession
    private var messageHandlers: [String: (WatchMessage) -> Void] = [:]

    override init() {
        session = WCSession.default
        super.init()

        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Session Management

    /// Activate the watch session
    func activateSession() {
        guard WCSession.isSupported() else { return }
        session.activate()
    }

    /// Send message to watch
    func sendMessage(_ message: WatchMessage) async throws {
        guard session.isReachable else {
            throw WatchError.notReachable
        }

        return try await withCheckedThrowingContinuation { continuation in
            session.sendMessage(message.dictionary, replyHandler: { reply in
                continuation.resume(returning: ())
            }, errorHandler: { error in
                continuation.resume(throwing: error)
            })
        }
    }

    /// Send message to watch with reply handler
    func sendMessageWithReply(_ message: WatchMessage) async throws -> WatchMessage {
        guard session.isReachable else {
            throw WatchError.notReachable
        }

        return try await withCheckedThrowingContinuation { continuation in
            session.sendMessage(message.dictionary, replyHandler: { reply in
                let replyMessage = WatchMessage(from: reply)
                continuation.resume(returning: replyMessage)
            }, errorHandler: { error in
                continuation.resume(throwing: error)
            })
        }
    }

    /// Transfer user info to watch (delivered even if app is not running)
    func transferUserInfo(_ message: WatchMessage) throws {
        guard session.isWatchAppInstalled else {
            throw WatchError.watchAppNotInstalled
        }

        session.transferUserInfo(message.dictionary)
    }

    /// Transfer file to watch
    func transferFile(_ file: URL, metadata: WatchMessage?) throws {
        guard session.isWatchAppInstalled else {
            throw WatchError.watchAppNotInstalled
        }

        session.transferFile(file, metadata: metadata?.dictionary)
    }

    // MARK: - Message Registration

    /// Register handler for specific message type
    func registerHandler(for messageType: String, handler: @escaping (WatchMessage) -> Void) {
        messageHandlers[messageType] = handler
    }

    /// Remove handler for message type
    func removeHandler(for messageType: String) {
        messageHandlers.removeValue(forKey: messageType)
    }

    // MARK: - Watch App Control

    /// Launch workout app on watch
    func launchWorkoutAppOnWatch() async throws {
        guard session.isWatchAppInstalled else {
            throw WatchError.watchAppNotInstalled
        }

        try await sendMessage(WatchMessage(type: .launchWorkoutApp, data: [:]))
    }

    /// Send workout data to watch
    func sendWorkoutData(_ workout: WorkoutData) async throws {
        let message = WatchMessage(type: .workoutData,
                                 data: [
                                    "sessionId": workout.sessionId.uuidString,
                                    "startTime": workout.startTime.timeIntervalSince1970,
                                    "currentSet": workout.currentSet,
                                    "totalSets": workout.totalSets,
                                    "elapsedTime": workout.elapsedTime,
                                    "heartRate": workout.heartRate ?? 0,
                                    "distance": workout.distance,
                                    "pace": workout.pace
                                 ])
        try await sendMessage(message)
    }

    /// Send sprint set to watch
    func sendSprintSet(_ sprintSet: SprintSetConfiguration) async throws {
        let message = WatchMessage(type: .sprintSet,
                                 data: [
                                    "name": sprintSet.name,
                                    "distance": sprintSet.distance,
                                    "targetTime": sprintSet.targetTime,
                                    "restBetweenReps": sprintSet.restBetweenReps,
                                    "repetitions": sprintSet.repetitions,
                                    "intensity": sprintSet.intensity.rawValue
                                 ])
        try await sendMessage(message)
    }

    /// Send heart rate data to watch
    func sendHeartRate(_ heartRate: Double, timestamp: Date) async throws {
        let message = WatchMessage(type: .heartRate,
                                 data: [
                                    "bpm": heartRate,
                                    "timestamp": timestamp.timeIntervalSince1970
                                 ])
        try await sendMessage(message)
    }

    /// Request health data from watch
    func requestHealthData(from startDate: Date, to endDate: Date) async throws -> HealthData {
        let message = WatchMessage(type: .requestHealthData,
                                 data: [
                                    "startDate": startDate.timeIntervalSince1970,
                                    "endDate": endDate.timeIntervalSince1970
                                 ])

        let reply = try await sendMessageWithReply(message)

        guard let healthData = HealthData(from: reply.data) else {
            throw WatchError.invalidResponse
        }

        return healthData
    }

    // MARK: - Data Structures

    struct WatchMessage {
        let type: MessageType
        let data: [String: Any]
        let timestamp: Date

        init(type: MessageType, data: [String: Any]) {
            self.type = type
            self.data = data
            self.timestamp = Date()
        }

        init(from dictionary: [String: Any]) {
            self.type = MessageType(rawValue: dictionary["type"] as? String ?? "") ?? .unknown
            self.data = dictionary["data"] as? [String: Any] ?? [:]
            self.timestamp = Date(timeIntervalSince1970: dictionary["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970)
        }

        var dictionary: [String: Any] {
            return [
                "type": type.rawValue,
                "data": data,
                "timestamp": timestamp.timeIntervalSince1970
            ]
        }
    }

    enum MessageType: String {
        case launchWorkoutApp = "launchWorkoutApp"
        case workoutData = "workoutData"
        case sprintSet = "sprintSet"
        case heartRate = "heartRate"
        case requestHealthData = "requestHealthData"
        case healthDataResponse = "healthDataResponse"
        case workoutComplete = "workoutComplete"
        case pauseWorkout = "pauseWorkout"
        case resumeWorkout = "resumeWorkout"
        case emergencyStop = "emergencyStop"
        case unknown = "unknown"
    }

    struct WorkoutData {
        let sessionId: UUID
        let startTime: Date
        let currentSet: Int
        let totalSets: Int
        let elapsedTime: TimeInterval
        let heartRate: Double?
        let distance: Double
        let pace: Double
    }

    struct HealthData {
        let heartRateSamples: [HeartRateSample]
        let workoutSessions: [WorkoutSession]
        let totalDistance: Double
        let totalActiveEnergy: Double

        init?(from data: [String: Any]) {
            guard let heartRateData = data["heartRateSamples"] as? [[String: Any]],
                  let workoutData = data["workoutSessions"] as? [[String: Any]] else {
                return nil
            }

            self.heartRateSamples = heartRateData.compactMap { HeartRateSample(from: $0) }
            self.workoutSessions = workoutData.compactMap { WorkoutSession(from: $0) }
            self.totalDistance = data["totalDistance"] as? Double ?? 0.0
            self.totalActiveEnergy = data["totalActiveEnergy"] as? Double ?? 0.0
        }
    }

    struct HeartRateSample {
        let bpm: Double
        let timestamp: Date

        init?(from data: [String: Any]) {
            guard let bpm = data["bpm"] as? Double,
                  let timestamp = data["timestamp"] as? TimeInterval else {
                return nil
            }
            self.bpm = bpm
            self.timestamp = Date(timeIntervalSince1970: timestamp)
        }
    }

    struct WorkoutSession {
        let startDate: Date
        let duration: TimeInterval
        let distance: Double
        let averageHeartRate: Double?

        init?(from data: [String: Any]) {
            guard let startTimestamp = data["startDate"] as? TimeInterval,
                  let duration = data["duration"] as? TimeInterval,
                  let distance = data["distance"] as? Double else {
                return nil
            }
            self.startDate = Date(timeIntervalSince1970: startTimestamp)
            self.duration = duration
            self.distance = distance
            self.averageHeartRate = data["averageHeartRate"] as? Double
        }
    }

    // MARK: - Error Handling

    enum WatchError: Error {
        case notReachable
        case watchAppNotInstalled
        case invalidResponse
        case sessionNotActivated
        case messageTooLarge
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.lastError = error
            } else {
                self.isPaired = session.isPaired
                self.isReachable = session.isReachable
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let watchMessage = WatchMessage(from: message)

        DispatchQueue.main.async {
            self.receivedMessages.append(watchMessage)

            // Call registered handler if available
            if let handler = self.messageHandlers[watchMessage.type.rawValue] {
                handler(watchMessage)
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        let watchMessage = WatchMessage(from: message)

        DispatchQueue.main.async {
            self.receivedMessages.append(watchMessage)

            // Call registered handler if available
            if let handler = self.messageHandlers[watchMessage.type.rawValue] {
                handler(watchMessage)
            }

            // Send empty reply for now
            replyHandler([:])
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        let watchMessage = WatchMessage(from: userInfo)

        DispatchQueue.main.async {
            self.receivedMessages.append(watchMessage)
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        // Handle received file
        let fileURL = file.fileURL
        let metadata = WatchMessage(from: file.metadata ?? [:])

        DispatchQueue.main.async {
            // Process received file
            NotificationCenter.default.post(name: .watchFileReceived,
                                          object: nil,
                                          userInfo: [
                                            "fileURL": fileURL,
                                            "metadata": metadata
                                          ])
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Handle session deactivation - reactivate if needed
        session.activate()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let watchFileReceived = Notification.Name("watchFileReceived")
}

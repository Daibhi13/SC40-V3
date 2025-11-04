// Rest/work timers
import Foundation
import Combine

public class WorkoutTimer: ObservableObject {
    @Published public var isRunning = false
    @Published public var elapsedTime: TimeInterval = 0
    private var startTime: Date?
    private var accumulatedTime: TimeInterval = 0
    private var timer: Timer?
    // MARK: - Timer Control
    
    public init() {}
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }
    
    public func pause() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
        accumulatedTime += Date().timeIntervalSince(startTime ?? Date())
    }
    
public func reset() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        elapsedTime = 0
        accumulatedTime = 0
        startTime = nil
    }
    
    private func updateElapsedTime() {
        guard let startTime = startTime else { return }
        elapsedTime = accumulatedTime + Date().timeIntervalSince(startTime)
    }
}

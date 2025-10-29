import Foundation
import Combine
import os.log

// MARK: - Real-Time Data Streaming Enhancement
// High-frequency, low-latency data streaming for live workouts

@MainActor
class RealTimeDataStream: ObservableObject {
    static let shared = RealTimeDataStream()
    
    // MARK: - Stream Properties
    @Published var isStreaming = false
    @Published var streamQuality: StreamQuality = .offline
    @Published var packetsPerSecond: Double = 0.0
    @Published var dataLossRate: Double = 0.0
    @Published var bufferHealth: Double = 1.0 // 0.0 = empty, 1.0 = full
    
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "RealTimeStream")
    private var streamTimer: Timer?
    private var dataBuffer: CircularBuffer<StreamPacket> = CircularBuffer(capacity: 100)
    private var sequenceNumber: UInt32 = 0
    private var lastAckSequence: UInt32 = 0
    
    enum StreamQuality {
        case offline
        case poor      // > 10% loss, > 500ms latency
        case fair      // 5-10% loss, 200-500ms latency  
        case good      // 1-5% loss, 50-200ms latency
        case excellent // < 1% loss, < 50ms latency
        
        var color: String {
            switch self {
            case .offline: return "gray"
            case .poor: return "red"
            case .fair: return "orange"
            case .good: return "blue"
            case .excellent: return "green"
            }
        }
    }
    
    struct StreamPacket: Equatable {
        let sequenceNumber: UInt32
        let timestamp: Date
        let dataType: DataType
        let payload: [String: Any]
        let priority: Priority
        
        static func == (lhs: StreamPacket, rhs: StreamPacket) -> Bool {
            return lhs.sequenceNumber == rhs.sequenceNumber &&
                   lhs.timestamp == rhs.timestamp &&
                   lhs.dataType == rhs.dataType &&
                   lhs.priority == rhs.priority
            // Note: payload comparison omitted as [String: Any] is not Equatable
        }
        
        enum DataType: String, CaseIterable {
            case gpsLocation = "gps"
            case heartRate = "hr"
            case pace = "pace"
            case distance = "distance"
            case repComplete = "rep"
            case phaseChange = "phase"
            case emergency = "emergency"
        }
        
        enum Priority: Int {
            case emergency = 0
            case critical = 1
            case high = 2
            case normal = 3
            case low = 4
        }
    }
    
    private init() {}
    
    // MARK: - Stream Control
    
    func startStream() {
        guard !isStreaming else { return }
        
        isStreaming = true
        sequenceNumber = 0
        lastAckSequence = 0
        
        // Start high-frequency streaming (10Hz for smooth real-time updates)
        streamTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.processStreamBuffer()
            }
        }
        
        logger.info("Real-time data stream started")
    }
    
    func stopStream() {
        isStreaming = false
        streamTimer?.invalidate()
        streamTimer = nil
        dataBuffer.clear()
        
        logger.info("Real-time data stream stopped")
    }
    
    // MARK: - Data Streaming
    
    func streamGPSData(latitude: Double, longitude: Double, speed: Double, accuracy: Double) {
        let packet = StreamPacket(
            sequenceNumber: getNextSequenceNumber(),
            timestamp: Date(),
            dataType: .gpsLocation,
            payload: [
                "latitude": latitude,
                "longitude": longitude,
                "speed": speed,
                "accuracy": accuracy
            ],
            priority: .high
        )
        
        queuePacket(packet)
    }
    
    func streamHeartRate(_ heartRate: Double) {
        let packet = StreamPacket(
            sequenceNumber: getNextSequenceNumber(),
            timestamp: Date(),
            dataType: .heartRate,
            payload: ["heartRate": heartRate],
            priority: .normal
        )
        
        queuePacket(packet)
    }
    
    func streamRepCompletion(repNumber: Int, time: Double, distance: Double) {
        let packet = StreamPacket(
            sequenceNumber: getNextSequenceNumber(),
            timestamp: Date(),
            dataType: .repComplete,
            payload: [
                "repNumber": repNumber,
                "time": time,
                "distance": distance,
                "timestamp": Date().timeIntervalSince1970
            ],
            priority: .critical
        )
        
        queuePacket(packet)
    }
    
    func streamPhaseChange(from: String, to: String) {
        let packet = StreamPacket(
            sequenceNumber: getNextSequenceNumber(),
            timestamp: Date(),
            dataType: .phaseChange,
            payload: [
                "fromPhase": from,
                "toPhase": to,
                "timestamp": Date().timeIntervalSince1970
            ],
            priority: .critical
        )
        
        queuePacket(packet)
    }
    
    func streamEmergencyStop() {
        let packet = StreamPacket(
            sequenceNumber: getNextSequenceNumber(),
            timestamp: Date(),
            dataType: .emergency,
            payload: [
                "action": "emergency_stop",
                "timestamp": Date().timeIntervalSince1970
            ],
            priority: .emergency
        )
        
        // Emergency packets bypass buffer and send immediately
        Task {
            await sendPacketImmediately(packet)
        }
    }
    
    // MARK: - Buffer Management
    
    private func queuePacket(_ packet: StreamPacket) {
        dataBuffer.append(packet)
        bufferHealth = Double(dataBuffer.count) / Double(dataBuffer.capacity)
        
        // If buffer is getting full, prioritize high-priority packets
        if bufferHealth > 0.8 {
            optimizeBuffer()
        }
    }
    
    private func optimizeBuffer() {
        // Remove low-priority packets to make room for high-priority ones
        let sortedPackets = dataBuffer.elements.sorted { $0.priority.rawValue < $1.priority.rawValue }
        
        // Keep only the most recent high-priority packets
        let keepCount = Int(Double(dataBuffer.capacity) * 0.7)
        let packetsToKeep = Array(sortedPackets.prefix(keepCount))
        
        dataBuffer.clear()
        packetsToKeep.forEach { dataBuffer.append($0) }
        
        logger.warning("Buffer optimized - kept \(packetsToKeep.count) high-priority packets")
    }
    
    private func processStreamBuffer() {
        guard isStreaming && !dataBuffer.isEmpty else { return }
        
        // Process packets in priority order
        let packetsToSend = dataBuffer.elements.sorted { $0.priority.rawValue < $1.priority.rawValue }
        
        Task {
            for packet in packetsToSend.prefix(5) { // Send up to 5 packets per cycle
                await sendPacket(packet)
                dataBuffer.remove(packet)
            }
            
            updateStreamMetrics()
        }
    }
    
    private func sendPacket(_ packet: StreamPacket) async {
        let message: [String: Any] = [
            "type": "stream_data",
            "dataType": packet.dataType.rawValue,
            "sequenceNumber": packet.sequenceNumber,
            "timestamp": packet.timestamp.timeIntervalSince1970,
            "payload": packet.payload,
            "priority": packet.priority.rawValue
        ]
        
        let success = await EnhancedConnectivityManager.shared.sendMessage(
            message, 
            priority: mapPriorityToConnectivity(packet.priority)
        )
        
        if success {
            lastAckSequence = packet.sequenceNumber
        } else {
            // Re-queue critical packets for retry
            if packet.priority.rawValue <= StreamPacket.Priority.critical.rawValue {
                queuePacket(packet)
            }
        }
    }
    
    private func sendPacketImmediately(_ packet: StreamPacket) async {
        let message: [String: Any] = [
            "type": "emergency_data",
            "dataType": packet.dataType.rawValue,
            "sequenceNumber": packet.sequenceNumber,
            "timestamp": packet.timestamp.timeIntervalSince1970,
            "payload": packet.payload
        ]
        
        _ = await EnhancedConnectivityManager.shared.sendCriticalWorkoutCommand(message)
    }
    
    // MARK: - Metrics & Quality Assessment
    
    private func updateStreamMetrics() {
        // Calculate packets per second
        let recentPackets = dataBuffer.elements.filter { 
            Date().timeIntervalSince($0.timestamp) < 1.0 
        }
        packetsPerSecond = Double(recentPackets.count)
        
        // Calculate data loss rate
        if sequenceNumber > 0 {
            let expectedPackets = sequenceNumber - lastAckSequence
            let lostPackets = max(0, Int(expectedPackets) - dataBuffer.count)
            dataLossRate = Double(lostPackets) / Double(sequenceNumber) * 100.0
        }
        
        // Update stream quality
        updateStreamQuality()
    }
    
    private func updateStreamQuality() {
        let connectivity = EnhancedConnectivityManager.shared
        
        if !connectivity.connectionState.description.contains("connected") {
            streamQuality = .offline
        } else if dataLossRate > 10 || connectivity.latency > 500 {
            streamQuality = .poor
        } else if dataLossRate > 5 || connectivity.latency > 200 {
            streamQuality = .fair
        } else if dataLossRate > 1 || connectivity.latency > 50 {
            streamQuality = .good
        } else {
            streamQuality = .excellent
        }
    }
    
    // MARK: - Helper Methods
    
    private func getNextSequenceNumber() -> UInt32 {
        sequenceNumber += 1
        return sequenceNumber
    }
    
    private func mapPriorityToConnectivity(_ priority: StreamPacket.Priority) -> EnhancedConnectivityManager.QueuedMessage.MessagePriority {
        switch priority {
        case .emergency, .critical:
            return .critical
        case .high:
            return .high
        case .normal:
            return .normal
        case .low:
            return .low
        }
    }
    
    // MARK: - Diagnostics
    
    func getStreamDiagnostics() -> [String: Any] {
        return [
            "isStreaming": isStreaming,
            "streamQuality": streamQuality,
            "packetsPerSecond": packetsPerSecond,
            "dataLossRate": dataLossRate,
            "bufferHealth": bufferHealth,
            "sequenceNumber": sequenceNumber,
            "lastAckSequence": lastAckSequence,
            "bufferedPackets": dataBuffer.count
        ]
    }
}

// MARK: - Circular Buffer Implementation

class CircularBuffer<T> {
    private var buffer: [T?]
    private var head = 0
    private var tail = 0
    private var size = 0
    let capacity: Int
    
    var count: Int { return size }
    var isEmpty: Bool { return size == 0 }
    var isFull: Bool { return size == capacity }
    
    var elements: [T] {
        return buffer.compactMap { $0 }
    }
    
    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }
    
    func append(_ element: T) {
        buffer[tail] = element
        tail = (tail + 1) % capacity
        
        if size == capacity {
            head = (head + 1) % capacity
        } else {
            size += 1
        }
    }
    
    func remove(_ element: T) where T: Equatable {
        for i in 0..<capacity {
            if buffer[i] != nil && buffer[i]! == element {
                buffer[i] = nil
                size = max(0, size - 1)
                break
            }
        }
    }
    
    func clear() {
        buffer = Array(repeating: nil, count: capacity)
        head = 0
        tail = 0
        size = 0
    }
}

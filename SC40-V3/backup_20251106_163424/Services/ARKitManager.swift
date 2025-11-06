import Foundation
import ARKit
import RealityKit
import SwiftUI
import Combine

/// ARKit integration for augmented reality sprint coaching and form analysis
@available(iOS 13.0, *)
@MainActor
class ARKitManager: NSObject, ObservableObject {
    static let shared = ARKitManager()
    
    @Published var isARSupported = false
    @Published var isSessionRunning = false
    @Published var trackingState: ARCamera.TrackingState = .notAvailable
    @Published var detectedPlanes: [ARPlaneAnchor] = []
    @Published var sprintLane: SprintLane?
    @Published var virtualCoach: VirtualCoach?
    
    private var arView: ARView?
    private var session: ARSession?
    private var cancellables = Set<AnyCancellable>()
    
    // Sprint tracking
    @Published var runnerPosition: SIMD3<Float> = SIMD3(0, 0, 0)
    @Published var runnerVelocity: Float = 0
    @Published var sprintDistance: Float = 0
    @Published var isSprintActive = false
    
    override init() {
        super.init()
        checkARSupport()
    }
    
    // MARK: - AR Setup
    
    private func checkARSupport() {
        isARSupported = ARWorldTrackingConfiguration.isSupported
        
        if isARSupported {
            print("✅ ARKit is supported on this device")
        } else {
            print("❌ ARKit is not supported on this device")
        }
    }
    
    func setupARSession(arView: ARView) {
        guard isARSupported else { return }
        
        self.arView = arView
        self.session = arView.session
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentation) {
            configuration.frameSemantics.insert(.personSegmentation)
        }
        
        arView.session.delegate = self
        arView.session.run(configuration)
        
        isSessionRunning = true
        
        // Setup gesture recognizers
        setupGestureRecognizers(for: arView)
        
        print("🚀 AR session started")
    }
    
    private func setupGestureRecognizers(for arView: ARView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = self.arView else { return }
        
        let location = gesture.location(in: arView)
        
        // Perform raycast to find horizontal plane
        let results = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal)
        
        if let result = results.first {
            createSprintLane(at: result.worldTransform)
        }
    }
    
    // MARK: - Sprint Lane Creation
    
    private func createSprintLane(at transform: simd_float4x4) {
        guard let arView = self.arView else { return }
        
        // Remove existing sprint lane
        if let existingLane = sprintLane {
            arView.scene.removeAnchor(existingLane.anchor)
        }
        
        // Create new sprint lane
        let anchor = AnchorEntity(world: transform)
        
        // Create 40-yard sprint lane (36.58 meters)
        let laneLength: Float = 36.58
        let laneWidth: Float = 1.22 // Standard lane width
        
        // Start line
        let startLine = createLine(width: laneWidth, height: 0.1, depth: 0.05, color: .green)
        startLine.position = SIMD3(0, 0, 0)
        anchor.addChild(startLine)
        
        // Finish line
        let finishLine = createLine(width: laneWidth, height: 0.1, depth: 0.05, color: .red)
        finishLine.position = SIMD3(0, 0, -laneLength)
        anchor.addChild(finishLine)
        
        // Lane markers every 10 yards
        for i in 1..<4 {
            let markerDistance = Float(i) * (laneLength / 4)
            let marker = createLine(width: laneWidth, height: 0.05, depth: 0.02, color: .white)
            marker.position = SIMD3(0, 0, -markerDistance)
            anchor.addChild(marker)
            
            // Distance text
            let text = createText("\(i * 10) YD", size: 0.1)
            text.position = SIMD3(laneWidth/2 + 0.2, 0.1, -markerDistance)
            anchor.addChild(text)
        }
        
        // Lane boundaries
        let leftBoundary = createLine(width: 0.02, height: 0.05, depth: laneLength, color: .white)
        leftBoundary.position = SIMD3(-laneWidth/2, 0, -laneLength/2)
        anchor.addChild(leftBoundary)
        
        let rightBoundary = createLine(width: 0.02, height: 0.05, depth: laneLength, color: .white)
        rightBoundary.position = SIMD3(laneWidth/2, 0, -laneLength/2)
        anchor.addChild(rightBoundary)
        
        // Add anchor to scene
        arView.scene.addAnchor(anchor)
        
        sprintLane = SprintLane(
            anchor: anchor,
            startPosition: SIMD3(0, 0, 0),
            finishPosition: SIMD3(0, 0, -laneLength),
            length: laneLength,
            width: laneWidth
        )
        
        // Create virtual coach
        createVirtualCoach(at: SIMD3(laneWidth/2 + 1, 0, -laneLength/2))
        
        print("🏃‍♂️ Sprint lane created: \(laneLength)m long")
    }
    
    private func createVirtualCoach(at position: SIMD3<Float>) {
        guard let _ = self.arView, let sprintLane = self.sprintLane else { return }
        
        // Create coach entity (simplified representation)
        let coachEntity = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            materials: [SimpleMaterial(color: .blue, isMetallic: false)]
        )
        coachEntity.position = position + SIMD3(0, 1.5, 0) // Elevated position
        
        // Add coaching text
        let coachingText = createText("Ready to sprint!", size: 0.05)
        coachingText.position = SIMD3(0, 0.3, 0)
        coachEntity.addChild(coachingText)
        
        sprintLane.anchor.addChild(coachEntity)
        
        virtualCoach = VirtualCoach(
            entity: coachEntity,
            textEntity: coachingText,
            position: position
        )
        
        print("🤖 Virtual coach created")
    }
    
    // MARK: - Sprint Tracking
    
    func startSprintTracking() {
        guard self.sprintLane != nil else { return }
        
        isSprintActive = true
        sprintDistance = 0
        runnerVelocity = 0
        
        updateVirtualCoach(message: "GO! Sprint to the finish!")
        
        print("🏁 Sprint tracking started")
    }
    
    func stopSprintTracking() -> ARSprintResult? {
        guard isSprintActive else { return nil }
        
        isSprintActive = false
        
        let result = ARSprintResult(
            distance: Double(sprintDistance),
            time: 0, // Would be calculated from actual timing
            averageVelocity: Double(runnerVelocity),
            maxVelocity: Double(runnerVelocity * 1.2) // Estimated
        )
        
        updateVirtualCoach(message: "Great job! Distance: \(String(format: "%.1f", sprintDistance))m")
        
        print("🏆 Sprint completed: \(sprintDistance)m")
        return result
    }
    
    private func updateVirtualCoach(message: String) {
        guard let virtualCoach = self.virtualCoach else { return }
        
        // Remove old text
        virtualCoach.entity.removeChild(virtualCoach.textEntity)
        
        // Create new text
        let newText = createText(message, size: 0.05)
        newText.position = SIMD3(0, 0.3, 0)
        virtualCoach.entity.addChild(newText)
        
        // Update virtual coach reference
        self.virtualCoach = VirtualCoach(
            entity: virtualCoach.entity,
            textEntity: newText,
            position: virtualCoach.position
        )
    }
    
    // MARK: - Helper Methods
    
    private func createLine(width: Float, height: Float, depth: Float, color: UIColor) -> ModelEntity {
        let mesh = MeshResource.generateBox(width: width, height: height, depth: depth)
        let material = SimpleMaterial(color: color, isMetallic: false)
        return ModelEntity(mesh: mesh, materials: [material])
    }
    
    private func createText(_ text: String, size: Float) -> ModelEntity {
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: CGFloat(size * 100)),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        
        let material = SimpleMaterial(color: .white, isMetallic: false)
        return ModelEntity(mesh: mesh, materials: [material])
    }
    
    // MARK: - Session Management
    
    func pauseSession() {
        session?.pause()
        isSessionRunning = false
    }
    
    func resumeSession() {
        guard let session = self.session else { return }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        session.run(configuration)
        isSessionRunning = true
    }
    
    func resetSession() {
        guard let arView = self.arView else { return }
        
        // Remove all anchors
        arView.scene.anchors.removeAll()
        
        // Reset state
        sprintLane = nil
        virtualCoach = nil
        detectedPlanes.removeAll()
        isSprintActive = false
        
        // Restart session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        print("🔄 AR session reset")
    }
}

// MARK: - ARSessionDelegate

@available(iOS 13.0, *)
extension ARKitManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        trackingState = frame.camera.trackingState
        
        // Track runner position if sprint is active
        if isSprintActive {
            updateRunnerTracking(frame: frame)
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                detectedPlanes.append(planeAnchor)
                print("✅ Detected horizontal plane: \(planeAnchor.identifier)")
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor,
               let index = detectedPlanes.firstIndex(where: { $0.identifier == planeAnchor.identifier }) {
                detectedPlanes[index] = planeAnchor
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                detectedPlanes.removeAll { $0.identifier == planeAnchor.identifier }
            }
        }
    }
    
    private func updateRunnerTracking(frame: ARFrame) {
        // This would use person segmentation and tracking
        // For now, we'll simulate tracking based on camera movement
        let cameraTransform = frame.camera.transform
        let cameraPosition = SIMD3(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        
        // Calculate distance from start line
        if let sprintLane = self.sprintLane {
            let distanceFromStart = distance(cameraPosition, sprintLane.startPosition)
            sprintDistance = max(sprintDistance, distanceFromStart)
            
            // Estimate velocity (simplified)
            runnerVelocity = distanceFromStart * 2 // Rough estimate
        }
    }
}

// MARK: - Supporting Types

struct SprintLane {
    let anchor: AnchorEntity
    let startPosition: SIMD3<Float>
    let finishPosition: SIMD3<Float>
    let length: Float
    let width: Float
}

struct VirtualCoach {
    let entity: ModelEntity
    let textEntity: ModelEntity
    let position: SIMD3<Float>
}

struct ARSprintResult {
    let distance: Double
    let time: TimeInterval
    let averageVelocity: Double
    let maxVelocity: Double
}

// MARK: - SwiftUI Integration

@available(iOS 13.0, *)
struct ARSprintCoachView: View {
    @StateObject private var arManager = ARKitManager.shared
    
    var body: some View {
        ZStack {
            if arManager.isARSupported {
                ARViewContainer(arManager: arManager)
                    .ignoresSafeArea()
                
                VStack {
                    // AR Status
                    HStack {
                        Circle()
                            .fill(arManager.isSessionRunning ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text(arManager.isSessionRunning ? "AR Active" : "AR Inactive")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Planes: \(arManager.detectedPlanes.count)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                    .padding()
                    
                    Spacer()
                    
                    // Controls
                    VStack(spacing: 16) {
                        if arManager.sprintLane != nil {
                            if arManager.isSprintActive {
                                Button("Stop Sprint") {
                                    _ = arManager.stopSprintTracking()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            } else {
                                Button("Start Sprint") {
                                    arManager.startSprintTracking()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }
                        } else {
                            Text("Tap on a flat surface to create sprint lane")
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                        }
                        
                        HStack(spacing: 20) {
                            Button("Reset") {
                                arManager.resetSession()
                            }
                            .buttonStyle(.bordered)
                            
                            Button(arManager.isSessionRunning ? "Pause" : "Resume") {
                                if arManager.isSessionRunning {
                                    arManager.pauseSession()
                                } else {
                                    arManager.resumeSession()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "arkit")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("AR Not Supported")
                        .font(.title2.bold())
                    
                    Text("This device doesn't support ARKit features required for AR sprint coaching.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
}

@available(iOS 13.0, *)
struct ARViewContainer: UIViewRepresentable {
    let arManager: ARKitManager
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arManager.setupARSession(arView: arView)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Updates handled by ARKitManager
    }
}

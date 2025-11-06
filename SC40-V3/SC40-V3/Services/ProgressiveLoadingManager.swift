import Foundation
import SwiftUI
import Combine

// MARK: - Progressive Loading Manager
// Handles progressive data loading to prevent blocking operations

@MainActor
class ProgressiveLoadingManager: ObservableObject {
    static let shared = ProgressiveLoadingManager()
    
    @Published var isGeneratingProgram = false
    @Published var generationProgress: Double = 0.0
    @Published var currentStage = ""
    @Published var estimatedTimeRemaining: TimeInterval = 0
    
    private var cancellables = Set<AnyCancellable>()
    private var startTime: Date?
    
    private init() {}
    
    // MARK: - Progressive Program Generation
    
    func generateProgramProgressively(
        userLevel: String,
        frequency: Int,
        userPreferences: UserSessionPreferences? = nil
    ) async -> [TrainingSession] {
        
        isGeneratingProgram = true
        generationProgress = 0.0
        startTime = Date()
        
        var allSessions: [TrainingSession] = []
        
        do {
            // Stage 1: Generate Week 1 (Critical for immediate use)
            currentStage = "Generating Week 1..."
            generationProgress = 0.1
            
            let week1Sessions = await generateWeekSessions(
                week: 1,
                userLevel: userLevel,
                frequency: frequency,
                userPreferences: userPreferences
            )
            allSessions.append(contentsOf: week1Sessions)
            
            // Stage 2: Generate Weeks 2-4 (Foundation Phase)
            currentStage = "Building foundation weeks..."
            
            for week in 2...4 {
                let weekSessions = await generateWeekSessions(
                    week: week,
                    userLevel: userLevel,
                    frequency: frequency,
                    userPreferences: userPreferences
                )
                allSessions.append(contentsOf: weekSessions)
                
                generationProgress = 0.1 + (Double(week - 1) * 0.15)
                updateEstimatedTime()
                
                // Small delay to prevent blocking
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            
            // Stage 3: Generate Weeks 5-8 (Development Phase)
            currentStage = "Creating development phase..."
            
            for week in 5...8 {
                let weekSessions = await generateWeekSessions(
                    week: week,
                    userLevel: userLevel,
                    frequency: frequency,
                    userPreferences: userPreferences
                )
                allSessions.append(contentsOf: weekSessions)
                
                generationProgress = 0.4 + (Double(week - 5) * 0.1)
                updateEstimatedTime()
                
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
            
            // Stage 4: Generate Weeks 9-12 (Peak Phase)
            currentStage = "Finalizing peak performance weeks..."
            
            for week in 9...12 {
                let weekSessions = await generateWeekSessions(
                    week: week,
                    userLevel: userLevel,
                    frequency: frequency,
                    userPreferences: userPreferences
                )
                allSessions.append(contentsOf: weekSessions)
                
                generationProgress = 0.7 + (Double(week - 9) * 0.075)
                updateEstimatedTime()
                
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
            
            // Stage 5: Validation and Optimization
            currentStage = "Validating and optimizing program..."
            generationProgress = 0.95
            
            let validatedSessions = await validateAndOptimizeSessions(allSessions)
            
            // Complete
            currentStage = "Program ready!"
            generationProgress = 1.0
            
            // Small delay to show completion
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            
            return validatedSessions
            
        } catch {
            print("🚨 Progressive generation failed: \(error)")
            currentStage = "Generation failed"
            
            // Return basic fallback program
            return await generateFallbackProgram(userLevel: userLevel, frequency: frequency)
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateWeekSessions(
        week: Int,
        userLevel: String,
        frequency: Int,
        userPreferences: UserSessionPreferences?
    ) async -> [TrainingSession] {
        
        // Use UnifiedSessionGenerator for actual generation
        let generator = UnifiedSessionGenerator.shared
        
        var weekSessions: [TrainingSession] = []
        
        for day in 1...frequency {
            let session = await Task.detached { @MainActor in
                return generator.generateDeterministicSession(
                    week: week,
                    day: day,
                    userLevel: userLevel,
                    frequency: frequency
                )
            }.value
            
            weekSessions.append(session)
        }
        
        return weekSessions
    }
    
    private func validateAndOptimizeSessions(_ sessions: [TrainingSession]) async -> [TrainingSession] {
        return await Task.detached {
            // Filter out invalid sessions
            let validSessions = sessions.compactMap { session -> TrainingSession? in
                guard !session.type.isEmpty,
                      !session.focus.isEmpty,
                      session.week >= 1 && session.week <= 12,
                      session.day >= 1 && session.day <= 7,
                      !session.sprints.isEmpty else {
                    return nil
                }
                
                let validSprints = session.sprints.allSatisfy { sprint in
                    sprint.distanceYards > 0 && sprint.reps > 0
                }
                
                return validSprints ? session : nil
            }
            
            return validSessions
        }.value
    }
    
    private func generateFallbackProgram(userLevel: String, frequency: Int) async -> [TrainingSession] {
        // Generate minimal viable program
        var fallbackSessions: [TrainingSession] = []
        
        for week in 1...12 {
            for day in 1...frequency {
                let session = TrainingSession(
                    id: UUID(),
                    week: week,
                    day: day,
                    type: "Basic Sprint Training",
                    focus: "Speed Development",
                    sprints: [
                        SprintSet(distanceYards: 20, reps: 4, intensity: "Moderate")
                    ],
                    accessoryWork: ["Dynamic Warm-up", "Cool-down Stretching"],
                    notes: "Fallback session - basic training structure"
                )
                fallbackSessions.append(session)
            }
        }
        
        return fallbackSessions
    }
    
    private func updateEstimatedTime() {
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let totalEstimated = elapsed / generationProgress
        estimatedTimeRemaining = max(0, totalEstimated - elapsed)
    }
    
    func resetProgress() {
        isGeneratingProgram = false
        generationProgress = 0.0
        currentStage = ""
        estimatedTimeRemaining = 0
        startTime = nil
    }
}

// MARK: - Progressive Loading View

struct ProgressiveLoadingView: View {
    @StateObject private var loadingManager = ProgressiveLoadingManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Loading Animation
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: loadingManager.generationProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: loadingManager.generationProgress)
                
                Text("\(Int(loadingManager.generationProgress * 100))%")
                    .font(.headline.bold())
                    .foregroundColor(.primary)
            }
            
            // Stage Information
            VStack(spacing: 8) {
                Text(loadingManager.currentStage)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if loadingManager.estimatedTimeRemaining > 0 {
                    Text("About \(Int(loadingManager.estimatedTimeRemaining)) seconds remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            ProgressView(value: loadingManager.generationProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 8)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}


#Preview {
    ProgressiveLoadingView()
}

import SwiftUI

struct QuickWinWorkoutView: View {
    let onComplete: () -> Void
    @State private var showWorkout = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.2, green: 0.1, blue: 0.3),
                        Color(red: 0.1, green: 0.05, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showWorkout {
                    // Quick Win completion screen
                    VStack(spacing: 30) {
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 16) {
                            Text("Quick Win Complete!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Great job! You've completed your first sprint training session.")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            print("🏆 Quick Win session completed")
                            onComplete()
                        }) {
                            Text("Continue to Training")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                } else {
                    // Quick Win introduction screen
                    VStack(spacing: 30) {
                        Spacer()
                        
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.yellow)
                            
                            Text("Quick Win Session")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Your First Sprint Training")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Session details card
                        VStack(spacing: 20) {
                            VStack(spacing: 12) {
                                Text("10–20–30 yd Pyramid")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Accel progression")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.yellow)
                            }
                            
                            // Session breakdown
                            VStack(spacing: 12) {
                                SessionDetailRow(icon: "figure.run", label: "Sprint Pattern", value: "10→20→30 yards")
                                SessionDetailRow(icon: "repeat", label: "Total Reps", value: "3 sprints")
                                SessionDetailRow(icon: "clock", label: "Rest Between", value: "2 min")
                                SessionDetailRow(icon: "target", label: "Focus", value: "Accel progression")
                            }
                            
                            // Encouragement
                            VStack(spacing: 8) {
                                Text("Perfect for beginners!")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.green)
                                
                                Text("This progressive pyramid builds speed gradually")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        // Action buttons
                        VStack(spacing: 16) {
                            Button(action: {
                                withAnimation {
                                    showWorkout = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Start My First Sprint!")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            
                            Button(action: {
                                // Skip Quick Win and go directly to TrainingView
                                onComplete()
                            }) {
                                Text("Maybe Later")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onComplete()
                    }
                    .foregroundColor(.white)
                }
            }
            #endif
        }
    }
}

// MARK: - Session Detail Row Component
struct SessionDetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    QuickWinWorkoutView(onComplete: {})
}

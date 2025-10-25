import SwiftUI

struct ContentView: View {
    var body: some View {
        // Horizontal Card Navigation System
        TabView {
            // Card 0: Sprint Timer Pro
            SprintTimerProCardView()
                .tag(0)
            
            // Card 1: User Profile
            UserProfileCardView()
                .tag(1)
            
            // Card 2: Training Session Example
            TrainingSessionCardView()
                .tag(2)
        }
        #if os(watchOS)
        .tabViewStyle(PageTabViewStyle())
        #endif
    }
}

// MARK: - Card Views

struct SprintTimerProCardView: View {
    @State private var showSprintTimerPro = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Sprint Timer Pro")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("👑 PRO")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
            
            Spacer()
            
            Text("Custom Workouts")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // Action Button
            Button(action: {
                showSprintTimerPro = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("CONFIGURE")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.85, blue: 0.1), Color(red: 1.0, green: 0.75, blue: 0.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.9),
                            Color.black.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.yellow.opacity(0.8), .orange.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .sheet(isPresented: $showSprintTimerPro) {
            Text("Sprint Timer Pro")
                .font(.title2)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        }
    }
}

struct UserProfileCardView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.blue)
            
            Text("Welcome")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text("David")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            VStack(spacing: 6) {
                HStack {
                    Text("Level:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("Intermediate")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                }
                
                HStack {
                    Text("PB:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("5.25s")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
            
            Spacer()
            
            // Action Button
            Button(action: {
                // Navigate to profile settings
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 12, weight: .bold))
                    Text("VIEW PROFILE")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.85, blue: 0.1), Color(red: 1.0, green: 0.75, blue: 0.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.4),
                            Color.purple.opacity(0.4),
                            Color.black.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

struct TrainingSessionCardView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("W1")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow)
                    .cornerRadius(6)
                
                Spacer()
                
                Text("D1")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
            }
            
            Text("SPEED")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.yellow)
                .tracking(1)
            
            Text("Acceleration")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Spacer()
            
            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("5")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.white)
                    
                    Text("×")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("40")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("YD")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Text("MAX")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Action Button
            Button(action: {
                // Start training session
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("START WORKOUT")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.85, blue: 0.1), Color(red: 1.0, green: 0.75, blue: 0.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.5),
                            Color.red.opacity(0.3),
                            Color.black.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.6), Color.red.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Canvas Previews

#if DEBUG
#Preview("1. Watch Content View") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("2. Horizontal Card View") {
    HorizontalCardWatchView()
        .preferredColorScheme(.dark)
}
#endif




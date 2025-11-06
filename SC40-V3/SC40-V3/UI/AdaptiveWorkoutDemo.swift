import SwiftUI

/// Standalone demo app to showcase the AdaptiveWorkoutHub
/// This provides a clean, working demonstration of the dual-platform workout system
struct AdaptiveWorkoutDemo: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Hero Section
                VStack(spacing: 16) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("SC40 Sprint Training")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Dual Platform Demo")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Key Feature Highlights
                VStack(alignment: .leading, spacing: 12) {
                    AdaptiveFeatureRow(icon: "iphone", title: "iPhone GPS Tracking", description: "Full session access with GPS precision")
                    AdaptiveFeatureRow(icon: "applewatch", title: "Apple Watch Integration", description: "Wrist-based convenience and heart rate")
                    AdaptiveFeatureRow(icon: "brain.head.profile", title: "Smart Selection", description: "Automatically choose optimal platform")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // Launch Button
                NavigationLink(destination: Text("Adaptive Workout Hub")) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.headline)
                        Text("Experience Dual Platform Workouts")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("SC40 Demo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

struct AdaptiveFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AdaptiveWorkoutDemo()
}

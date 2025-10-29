import SwiftUI

struct PreOnboardingView: View {
    @State private var animateGradient = false
    @State private var showPulse = false
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: animateGradient ? [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color.black
                ] : [
                    Color.black,
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.2, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateGradient)
            
            VStack(spacing: 12) {
                // Sprint icon with pulse animation
                Image(systemName: "figure.run")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.yellow)
                    .scaleEffect(showPulse ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showPulse)
                
                // App branding
                Text("SC40-V3")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text("Sprint Training")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer().frame(height: 8)
                
                // User greeting with fallback
                VStack(spacing: 4) {
                    Text("Ready, Sprinter?")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Training Mode")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer().frame(height: 12)
                
                // Setup reminder (non-intrusive)
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "iphone")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("Complete setup on iPhone")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Text("for personalized training")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 4)
                
                Spacer().frame(height: 8)
                
                // Quick action button
                Button(action: {
                    // Show basic workout options or sync prompt
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.caption)
                        Text("Start Basic Training")
                            .font(.caption.bold())
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .onAppear {
            animateGradient = true
            showPulse = true
        }
    }
}

// MARK: - Alternative Motivational Version
struct PreOnboardingMotivationalView: View {
    @State private var currentMessageIndex = 0
    @State private var showMessage = true
    
    private let motivationalMessages = [
        "Future Champion",
        "Speed Awaits",
        "Ready to Fly?",
        "Sprint Warrior"
    ]
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.3, blue: 0.5),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Large 40 branding
                Text("40")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                
                // Rotating motivational message
                Text(motivationalMessages[currentMessageIndex])
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .opacity(showMessage ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5), value: showMessage)
                
                Text("Getting Started")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
                
                Spacer().frame(height: 12)
                
                // Setup prompt
                VStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Set up your profile")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    
                    Text("on iPhone to unlock")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text("your potential")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .onAppear {
            startMessageRotation()
        }
    }
    
    private func startMessageRotation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation {
                showMessage = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentMessageIndex = (currentMessageIndex + 1) % motivationalMessages.count
                withAnimation {
                    showMessage = true
                }
            }
        }
    }
}

#Preview("Sprint-Ready Style") {
    PreOnboardingView()
}

#Preview("Motivational Style") {
    PreOnboardingMotivationalView()
}

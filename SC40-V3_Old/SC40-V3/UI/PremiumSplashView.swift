import SwiftUI

struct PremiumSplashView: View {
    @State private var showContent = false
    @State private var pulseAnimation = false
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Premium gradient background matching the image
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 0.0),
                    .init(color: Color(red: 0.1, green: 0.2, blue: 0.35), location: 0.3),
                    .init(color: Color(red: 0.15, green: 0.25, blue: 0.45), location: 0.5),
                    .init(color: Color(red: 0.2, green: 0.15, blue: 0.35), location: 0.7),
                    .init(color: Color(red: 0.1, green: 0.05, blue: 0.25), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                Spacer()
                
                // Content container
                VStack(spacing: 40) {
                    // "SPRINT COACH" text
                    Text("SPRINT COACH")
                        .font(.system(size: 18, weight: .medium, design: .default))
                        .foregroundColor(.white)
                        .tracking(4)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0).delay(0.5), value: showContent)
                    
                    // Large "40" numbers with premium styling
                    Text("40")
                        .font(.system(size: 180, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.7, green: 0.9, blue: 0.6))
                        .shadow(color: Color(red: 0.7, green: 0.9, blue: 0.6).opacity(0.3), radius: 30)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1 : 0)
                        .animation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.8), value: showContent)
                    
                    // Runner icon in circle with pulse animation
                    ZStack {
                        Circle()
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 2)
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .opacity(pulseAnimation ? 0.5 : 0.8)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
                        
                        Circle()
                            .fill(Color.cyan.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "figure.run")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.cyan)
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0).delay(1.2), value: showContent)
                    
                    // "Elite Sprint Training" subtitle
                    Text("Elite Sprint Training")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.white.opacity(0.9))
                        .tracking(1)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0).delay(1.5), value: showContent)
                }
                
                Spacer()
                
                // "Tap to continue" at bottom
                Button(action: {
                    HapticManager.shared.light()
                    onContinue()
                }) {
                    Text("Tap to continue")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 60)
                }
                .opacity(showContent ? 1 : 0)
                .animation(.easeInOut(duration: 1.0).delay(2.0), value: showContent)
            }
        }
        .onAppear {
            showContent = true
            pulseAnimation = true
        }
        .onTapGesture {
            HapticManager.shared.light()
            onContinue()
        }
    }
}

#Preview {
    PremiumSplashView(onContinue: {})
}

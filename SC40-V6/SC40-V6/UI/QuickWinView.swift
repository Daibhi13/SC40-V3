import SwiftUI

struct QuickWinView: View {
    @State private var showContent = false
    let userName: String
    let onStartSession: () -> Void
    let onMaybeLater: () -> Void
    
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
                VStack(spacing: 32) {
                    // Welcome header with wave emoji
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Text("Welcome, \(userName)!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("👋")
                                .font(.system(size: 28))
                        }
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(0.3), value: showContent)
                        
                        Text("Let's get your first win!")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeInOut(duration: 0.8).delay(0.5), value: showContent)
                    }
                    
                    // Main card
                    VStack(spacing: 24) {
                        // Runner icon
                        ZStack {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "figure.run")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        }
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.7), value: showContent)
                        
                        // Title and description
                        VStack(spacing: 12) {
                            Text("Quick 10-Minute Warm-Up")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Complete a simple warm-up session to get started and unlock your first achievement")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(0.9), value: showContent)
                        
                        // Feature list
                        VStack(spacing: 12) {
                            QuickWinFeatureRow(
                                icon: "checkmark.circle.fill",
                                text: "Easy to follow",
                                color: .green
                            )
                            
                            QuickWinFeatureRow(
                                icon: "clock.fill",
                                text: "Only 10 minutes",
                                color: .blue
                            )
                            
                            QuickWinFeatureRow(
                                icon: "trophy.fill",
                                text: "Unlock first badge",
                                color: Color(red: 1.0, green: 0.8, blue: 0.0)
                            )
                            
                            QuickWinFeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                text: "Start tracking progress",
                                color: .purple
                            )
                        }
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(1.1), value: showContent)
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.white.opacity(0.15), location: 0.0),
                                        .init(color: Color.white.opacity(0.08), location: 1.0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    )
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeInOut(duration: 1.0).delay(0.6), value: showContent)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    // Start button
                    Button(action: {
                        HapticManager.shared.medium()
                        onStartSession()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("Start Quick Win Session")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color(red: 1.0, green: 0.8, blue: 0.0), location: 0.0),
                                            .init(color: Color(red: 1.0, green: 0.6, blue: 0.0), location: 1.0)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.4), radius: 12, x: 0, y: 6)
                        )
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8).delay(1.3), value: showContent)
                    
                    // Maybe later button
                    Button(action: {
                        HapticManager.shared.light()
                        onMaybeLater()
                    }) {
                        Text("Maybe Later")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(height: 44)
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8).delay(1.5), value: showContent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            showContent = true
        }
    }
}

// MARK: - Feature Row Component

// Note: QuickWinFeatureRow is defined in ContentView.swift

#Preview {
    QuickWinView(
        userName: "David",
        onStartSession: {},
        onMaybeLater: {}
    )
}

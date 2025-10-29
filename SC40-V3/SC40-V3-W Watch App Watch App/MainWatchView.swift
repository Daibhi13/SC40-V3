import SwiftUI

struct MainWatchView: View {
    // TODO: Re-enable when WatchAppStateManager is available
    // @StateObject private var appState = WatchAppStateManager.shared
    @State private var showingWorkout = false
    @State private var animateElements = false
    
    var body: some View {
        ZStack {
            // Dynamic background based on state
            backgroundView
            
            if UserDefaults.standard.bool(forKey: "onboardingComplete") {
                // Post-onboarding: Full featured interface
                postOnboardingView
            } else {
                // Pre-onboarding: Motivational interface
                preOnboardingView
            }
        }
        .onAppear {
            animateElements = true
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        LinearGradient(
            colors: UserDefaults.standard.bool(forKey: "onboardingComplete") ? [
                Color.black,
                Color(red: 0.1, green: 0.2, blue: 0.4),
                Color.black
            ] : [
                Color.black,
                Color(red: 0.2, green: 0.1, blue: 0.3),
                Color(red: 0.1, green: 0.05, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 2), value: UserDefaults.standard.bool(forKey: "onboardingComplete"))
    }
    
    // MARK: - Pre-Onboarding View
    
    private var preOnboardingView: some View {
        VStack(spacing: 12) {
            // Sprint icon with animation
            Image(systemName: "figure.run")
                .font(.system(size: 35, weight: .bold))
                .foregroundColor(.yellow)
                .scaleEffect(animateElements ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateElements)
            
            // App branding
            Text("SC40-V3")
                .font(.title3.bold())
                .foregroundColor(.white)
            
            // Motivational greeting
            Text("Ready to Sprint?")
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Status badge
            Text("Universal Mode")
                .font(.caption.bold())
                .foregroundColor(.yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(8)
            
            Spacer().frame(height: 8)
            
            // Basic training button
            Button(action: {
                showingWorkout = true
            }) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.caption)
                    Text("Basic Training")
                        .font(.caption.bold())
                }
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yellow)
                .cornerRadius(12)
            }
            
            Spacer().frame(height: 6)
            
            // Setup reminder
            VStack(spacing: 3) {
                HStack {
                    Image(systemName: "iphone")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("Setup on iPhone")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Text("for personalized training")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
    
    // MARK: - Post-Onboarding View
    
    private var postOnboardingView: some View {
        VStack(spacing: 10) {
            // Header with user info
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.title3)
                        .foregroundColor(.yellow)
                    Text("SC40-V3")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                }
                
                Text("Welcome back, \(UserDefaults.standard.string(forKey: "userName") ?? "Sprinter")!")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            
            // User stats
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(UserDefaults.standard.string(forKey: "userLevel") ?? "Training Mode")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                    Text("Level")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                
                VStack(spacing: 2) {
                    Text("Ready")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Program")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer().frame(height: 8)
            
            // Main action buttons
            VStack(spacing: 8) {
                Button(action: {
                    showingWorkout = true
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.subheadline)
                        Text("Start Training")
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.yellow)
                    .cornerRadius(12)
                }
                
                HStack(spacing: 8) {
                    Button(action: {
                        // Show time trial
                    }) {
                        HStack {
                            Image(systemName: "stopwatch")
                                .font(.caption)
                            Text("Time Trial")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        // Show progress
                    }) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.caption)
                            Text("Progress")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Sync status
            Text("Complete setup on iPhone for personalized training")
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Supporting Views
// Note: Using StatBadge from ContentView to avoid duplication

#Preview("Pre-Onboarding") {
    MainWatchView()
        .onAppear {
            UserDefaults.standard.set(false, forKey: "onboardingComplete")
        }
}

#Preview("Post-Onboarding") {
    MainWatchView()
        .onAppear {
            UserDefaults.standard.set(true, forKey: "onboardingComplete")
            UserDefaults.standard.set("David", forKey: "userName")
            UserDefaults.standard.set("Intermediate", forKey: "userLevel")
        }
}

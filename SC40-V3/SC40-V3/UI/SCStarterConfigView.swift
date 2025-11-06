import SwiftUI

struct SCStarterConfigView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDistance = 40
    @State private var selectedReps = 4
    @State private var selectedRest = 3
    @State private var showWorkout = false
    @State private var showContent = false
    
    // Distance options: 40yd to 200yd in increments
    private let distanceOptions = [
        40, 50, 60, 70, 80, 90, 100,
        110, 120, 130, 140, 150, 160, 170, 180, 190, 200 // all yards
    ]
    
    private let repOptions = Array(1...10)
    private let restOptions = Array(1...10) // minutes
    
    var body: some View {
        ZStack {
            // Premium gradient background
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
                // Navigation Header with Back Button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "stopwatch.fill")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        }
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3), value: showContent)
                        
                        VStack(spacing: 8) {
                            Text("SC Starter")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("GPS-Verified Sprint Training")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(0.5), value: showContent)
                    }
                    .padding(.top, 40)
                    
                    // Configuration Cards
                    VStack(spacing: 20) {
                        // Distance Configuration
                        ConfigCard(
                            title: "Distance",
                            subtitle: "40 yards to 200 yards",
                            icon: "ruler.fill",
                            showContent: showContent,
                            delay: 0.7
                        ) {
                            VStack(spacing: 16) {
                                Text("Select Distance")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                    ForEach(distanceOptions, id: \.self) { distance in
                                        Button(action: {
                                            selectedDistance = distance
                                            HapticManager.shared.light()
                                        }) {
                                            VStack(spacing: 4) {
                                                Text("\(distance)")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(selectedDistance == distance ? .black : .white)
                                                
                                                Text("yd")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(selectedDistance == distance ? .black.opacity(0.7) : .white.opacity(0.7))
                                            }
                                            .frame(height: 50)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                selectedDistance == distance ?
                                                Color(red: 1.0, green: 0.8, blue: 0.0) :
                                                Color.white.opacity(0.1)
                                            )
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        selectedDistance == distance ?
                                                        Color(red: 1.0, green: 0.8, blue: 0.0) :
                                                        Color.white.opacity(0.2),
                                                        lineWidth: 1
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Reps Configuration
                        ConfigCard(
                            title: "Repetitions",
                            subtitle: "1 to 10 sprints",
                            icon: "repeat.circle.fill",
                            showContent: showContent,
                            delay: 0.9
                        ) {
                            VStack(spacing: 16) {
                                Text("Select Reps")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                    ForEach(repOptions, id: \.self) { rep in
                                        Button(action: {
                                            selectedReps = rep
                                            HapticManager.shared.light()
                                        }) {
                                            Text("\(rep)")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(selectedReps == rep ? .black : .white)
                                                .frame(width: 50, height: 50)
                                                .background(
                                                    selectedReps == rep ?
                                                    Color(red: 1.0, green: 0.8, blue: 0.0) :
                                                    Color.white.opacity(0.1)
                                                )
                                                .cornerRadius(25)
                                                .overlay(
                                                    Circle()
                                                        .stroke(
                                                            selectedReps == rep ?
                                                            Color(red: 1.0, green: 0.8, blue: 0.0) :
                                                            Color.white.opacity(0.2),
                                                            lineWidth: 1
                                                        )
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Rest Configuration
                        ConfigCard(
                            title: "Rest Period",
                            subtitle: "1 to 10 minutes",
                            icon: "pause.circle.fill",
                            showContent: showContent,
                            delay: 1.1
                        ) {
                            VStack(spacing: 16) {
                                Text("Select Rest Time")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                    ForEach(restOptions, id: \.self) { rest in
                                        Button(action: {
                                            selectedRest = rest
                                            HapticManager.shared.light()
                                        }) {
                                            VStack(spacing: 2) {
                                                Text("\(rest)")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(selectedRest == rest ? .black : .white)
                                                
                                                Text("min")
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(selectedRest == rest ? .black.opacity(0.7) : .white.opacity(0.7))
                                            }
                                            .frame(width: 50, height: 50)
                                            .background(
                                                selectedRest == rest ?
                                                Color(red: 1.0, green: 0.8, blue: 0.0) :
                                                Color.white.opacity(0.1)
                                            )
                                            .cornerRadius(25)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        selectedRest == rest ?
                                                        Color(red: 1.0, green: 0.8, blue: 0.0) :
                                                        Color.white.opacity(0.2),
                                                        lineWidth: 1
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Start Workout Button
                    Button(action: {
                        HapticManager.shared.medium()
                        showWorkout = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("Start Workout")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.0),
                                    Color(red: 1.0, green: 0.6, blue: 0.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8).delay(1.3), value: showContent)
                    .padding(.horizontal, 20)
                    
                    // Configuration Summary
                    VStack(spacing: 12) {
                        Text("Workout Summary")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            SummaryItem(
                                title: "Distance",
                                value: "\(selectedDistance)yd",
                                icon: "ruler.fill"
                            )
                            
                            SummaryItem(
                                title: "Reps",
                                value: "\(selectedReps)",
                                icon: "repeat.circle.fill"
                            )
                            
                            SummaryItem(
                                title: "Rest",
                                value: "\(selectedRest)min",
                                icon: "pause.circle.fill"
                            )
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8).delay(1.5), value: showContent)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            showContent = true
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showWorkout) {
            SCStarterWorkoutView(
                distance: selectedDistance,
                reps: selectedReps,
                restMinutes: selectedRest
            )
        }
    }
}

// MARK: - Config Card

struct ConfigCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let showContent: Bool
    let delay: Double
    let content: () -> Content
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Content
            content()
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
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
                    RoundedRectangle(cornerRadius: 20)
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
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .opacity(showContent ? 1 : 0)
        .animation(.easeInOut(duration: 0.8).delay(delay), value: showContent)
    }
}

// MARK: - Summary Item

struct SummaryItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

struct SCStarterConfigView_Previews: PreviewProvider {
    static var previews: some View {
        SCStarterConfigView()
    }
}

import SwiftUI

struct ContentView: View {
    @State private var selectedWeek = 1
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // iPhone TrainingView exact background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),  // Dark blue top
                        Color(red: 0.2, green: 0.1, blue: 0.3),  // Purple middle
                        Color(red: 0.1, green: 0.05, blue: 0.2)  // Dark purple bottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // iPhone glass effect overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.clear,
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top padding to respect system time area
                    Spacer()
                        .frame(height: 16)
                    
                    // HORIZONTAL CARD NAVIGATION SYSTEM
                    // Card Layout: [Card 0] ← → [Card 1] ← → [Card 2] ← → [Card 3] ← → [Card N...]
                    //                ↓           ↓           ↓           ↓           ↓
                    //           Sprint Timer  User Profile  Training   Training   Training
                    //              Pro                     Session    Session    Session
                    
                    TabView(selection: $selectedWeek) {
                        // Card 0: Sprint Timer Pro
                        SprintTimerProCardAdaptive(geometry: geometry)
                            .tag(0)
                        
                        // Card 1: Personal Record (iPhone match)
                        PersonalRecordCardAdaptive(geometry: geometry)
                            .tag(1)
                        
                        // Card 2+: Training Sessions (iPhone match with completion tracking)
                        ForEach(1...8, id: \.self) { sessionIndex in
                            let week = (sessionIndex - 1) / 4 + 1
                            let day = (sessionIndex - 1) % 4 + 1
                            
                            TrainingSessionCardAdaptive(
                                week: week,
                                day: day,
                                isCompleted: sessionIndex <= 2, // Mock completion status
                                isNext: sessionIndex == 3, // Next workout
                                geometry: geometry
                            )
                            .tag(sessionIndex + 1)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: geometry.size.height * 0.75)
                    .onAppear {
                        // Navigate to next workout on login
                        selectedWeek = 3 // Next workout (Day 3)
                    }
                    
                    Spacer()
                        .frame(height: 16)
                    
                    // Start Sprint Button
                    StartSprintButtonWatch(geometry: geometry)
                        .padding(.horizontal, geometry.size.width * 0.075)
                        .padding(.bottom, 16)
                }
            }
        }
    }
}

// MARK: - Polished Card Components (Perfect Proportions & Complete Details)

// Card 0: Sprint Timer Pro (Adaptive sizing for all watch sizes)
struct SprintTimerProCardAdaptive: View {
    let geometry: GeometryProxy
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: geometry.size.width * 0.03) {
                HStack {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: geometry.size.width * 0.09, weight: .bold))
                        .foregroundColor(.yellow)
                        .frame(maxHeight: geometry.size.height * 0.08)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$4.99")
                            .font(.system(size: geometry.size.width * 0.08, weight: .bold))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.6)
                        
                        Text("Upgrade")
                            .font(.system(size: geometry.size.width * 0.05, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .minimumScaleFactor(0.6)
                    }
                }
                
                VStack(alignment: .leading, spacing: geometry.size.width * 0.02) {
                    Text("Sprint Timer Pro")
                        .font(.system(size: geometry.size.width * 0.1, weight: .bold))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                    
                    Text("Unlock advanced training features")
                        .font(.system(size: geometry.size.width * 0.065, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.6)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: geometry.size.width * 0.02)
                
                HStack {
                    Text("• Custom workouts")
                        .font(.system(size: geometry.size.width * 0.055, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .minimumScaleFactor(0.6)
                        .lineLimit(nil)
                    
                    Spacer()
                    
                    Text("PRO")
                        .font(.system(size: geometry.size.width * 0.05, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, geometry.size.width * 0.04)
                        .padding(.vertical, geometry.size.width * 0.015)
                        .background(Color.yellow)
                        .cornerRadius(6)
                        .minimumScaleFactor(0.6)
                }
            }
            .padding(geometry.size.width * 0.1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: geometry.size.height * 0.65)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.yellow.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// Card 1: Personal Record (Adaptive sizing for all watch sizes)
struct PersonalRecordCardAdaptive: View {
    let geometry: GeometryProxy
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: geometry.size.width * 0.025) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: geometry.size.width * 0.08, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        .frame(maxHeight: geometry.size.height * 0.06)
                    
                    Spacer()
                    
                    Text("40 YARDS DASH")
                        .font(.system(size: geometry.size.width * 0.05, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .minimumScaleFactor(0.6)
                        .lineLimit(nil)
                        .multilineTextAlignment(.trailing)
                }
                
                Text("PERSONAL RECORD")
                    .font(.system(size: geometry.size.width * 0.06, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(geometry.size.width * 0.006)
                    .minimumScaleFactor(0.6)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                
                HStack(alignment: .bottom, spacing: geometry.size.width * 0.02) {
                    Text("5.25")
                        .font(.system(size: geometry.size.width * 0.16, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.9, blue: 0.7),
                                    Color(red: 1.0, green: 0.8, blue: 0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    
                    Text("SEC")
                        .font(.system(size: geometry.size.width * 0.06, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .minimumScaleFactor(0.6)
                        .padding(.bottom, geometry.size.width * 0.01)
                }
                
                Spacer(minLength: geometry.size.width * 0.02)
                
                HStack {
                    Text("Your best time")
                        .font(.system(size: geometry.size.width * 0.05, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .minimumScaleFactor(0.6)
                        .lineLimit(nil)
                    
                    Spacer()
                    
                    Text("ELITE")
                        .font(.system(size: geometry.size.width * 0.045, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, geometry.size.width * 0.03)
                        .padding(.vertical, geometry.size.width * 0.01)
                        .background(Color(red: 1.0, green: 0.8, blue: 0.0))
                        .cornerRadius(4)
                        .minimumScaleFactor(0.6)
                }
            }
            .padding(geometry.size.width * 0.1)
        }
        .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// Card 2+: Training Sessions (Adaptive sizing for all watch sizes)
struct TrainingSessionCardAdaptive: View {
    let week: Int
    let day: Int
    let isCompleted: Bool
    let isNext: Bool
    let geometry: GeometryProxy
    
    private var sessionData: (type: String, focus: String, sprints: String, restTime: String, intensity: String, description: String) {
        switch (week, day) {
        case (1, 1): return ("50 YD SPRINTS", "ACCEL → TOP SPEED", "5 × 50", "REST: 3 MIN", "MAX", "CHAMPIONS ARE MADE HERE")
        case (1, 2): return ("TEMPO", "ENDURANCE BUILD", "4 × 60", "REST: 2 MIN", "SUB", "BUILD YOUR ENGINE")
        case (1, 3): return ("POWER", "EXPLOSIVE START", "6 × 40", "REST: 4 MIN", "MAX", "EXPLOSIVE POWER")
        case (1, 4): return ("RECOVERY", "ACTIVE RECOVERY", "3 × 30", "REST: 2 MIN", "EASY", "RECOVERY SESSION")
        case (2, 1): return ("50 YD SPRINTS", "ACCELERATION", "6 × 50", "REST: 3 MIN", "MAX", "SPEED DEVELOPMENT")
        case (2, 2): return ("TEMPO", "SUSTAINED PACE", "5 × 70", "REST: 2 MIN", "SUB", "ENDURANCE BUILD")
        case (2, 3): return ("POWER", "FORCE DEVELOPMENT", "7 × 40", "REST: 4 MIN", "MAX", "POWER TRAINING")
        case (2, 4): return ("RECOVERY", "MOVEMENT PREP", "4 × 30", "REST: 2 MIN", "EASY", "ACTIVE RECOVERY")
        default: return ("50 YD SPRINTS", "SPRINT TRAINING", "5 × 50", "REST: 3 MIN", "MAX", "CHAMPIONS ARE MADE HERE")
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: geometry.size.width * 0.02) {
                // Header badges with completion status
                HStack {
                    Text("WEEK \(week)")
                        .font(.system(size: geometry.size.width * 0.045, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, geometry.size.width * 0.03)
                        .padding(.vertical, geometry.size.width * 0.015)
                        .background(Color(red: 1.0, green: 0.85, blue: 0.1))
                        .cornerRadius(4)
                        .minimumScaleFactor(0.6)
                    
                    Spacer()
                    
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: geometry.size.width * 0.07, weight: .bold))
                            .foregroundColor(.green)
                            .frame(maxHeight: geometry.size.height * 0.05)
                    } else if isNext {
                        Text("NEXT")
                            .font(.system(size: geometry.size.width * 0.045, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, geometry.size.width * 0.03)
                            .padding(.vertical, geometry.size.width * 0.015)
                            .background(Color.orange)
                            .cornerRadius(4)
                            .minimumScaleFactor(0.6)
                    } else {
                        Text(sessionData.type)
                            .font(.system(size: geometry.size.width * 0.04, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, geometry.size.width * 0.03)
                            .padding(.vertical, geometry.size.width * 0.015)
                            .background(Color(red: 1.0, green: 0.85, blue: 0.1))
                            .cornerRadius(4)
                            .minimumScaleFactor(0.6)
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Day and focus
                HStack(alignment: .bottom, spacing: geometry.size.width * 0.02) {
                    Text("DAY")
                        .font(.system(size: geometry.size.width * 0.055, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(geometry.size.width * 0.004)
                        .minimumScaleFactor(0.6)
                    
                    Text("\(day)")
                        .font(.system(size: geometry.size.width * 0.12, weight: .black))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.6)
                }
                
                Text(sessionData.focus.uppercased())
                    .font(.system(size: geometry.size.width * 0.06, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(geometry.size.width * 0.0015)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.leading)
                
                // Sprint details - compact
                VStack(alignment: .leading, spacing: geometry.size.width * 0.02) {
                    HStack(alignment: .bottom, spacing: geometry.size.width * 0.02) {
                        Text(sessionData.sprints)
                            .font(.system(size: geometry.size.width * 0.07, weight: .bold))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.6)
                        
                        Text("YD")
                            .font(.system(size: geometry.size.width * 0.05, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .minimumScaleFactor(0.6)
                        
                        Spacer()
                        
                        Text(sessionData.intensity)
                            .font(.system(size: geometry.size.width * 0.045, weight: .black))
                            .foregroundColor(.black)
                            .padding(.horizontal, geometry.size.width * 0.03)
                            .padding(.vertical, geometry.size.width * 0.01)
                            .background(Color.white)
                            .cornerRadius(4)
                            .minimumScaleFactor(0.6)
                    }
                    
                    Text(sessionData.restTime)
                        .font(.system(size: geometry.size.width * 0.05, weight: .bold))
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1.0))
                        .minimumScaleFactor(0.6)
                        .lineLimit(nil)
                    
                    Text(sessionData.description)
                        .font(.system(size: geometry.size.width * 0.045, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(geometry.size.width * 0.001)
                        .minimumScaleFactor(0.6)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: geometry.size.width * 0.02)
            }
            .padding(geometry.size.width * 0.1)
        }
        .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            // iPhone TrainingView session card background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.1, blue: 0.25).opacity(0.9),
                            Color(red: 0.1, green: 0.05, blue: 0.2).opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: isNext ? [
                            Color.orange.opacity(0.6),
                            Color.orange.opacity(0.3)
                        ] : isCompleted ? [
                            Color.green.opacity(0.4),
                            Color.green.opacity(0.2)
                        ] : [
                            Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.4),
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isNext ? 3 : 2
                )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Start Sprint Button (iPhone TrainingView exact styling)
struct StartSprintButtonWatch: View {
    let geometry: GeometryProxy
    
    var body: some View {
        Button(action: {
            // Handle sprint start
        }) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .bold))
                
                Text("START SPRINT")
                    .font(.system(size: 14, weight: .black))
                    .tracking(0.5)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, geometry.size.height < 200 ? 10 : 12) // Adaptive height 35-40pt
            .background(
                // iPhone TrainingView exact golden gradient
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.85, blue: 0.1),
                        Color(red: 1.0, green: 0.75, blue: 0.0),
                        Color(red: 0.95, green: 0.65, blue: 0.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(
                color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.4),
                radius: 2,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#if DEBUG
#Preview("ContentView") {
    ContentView()
        .preferredColorScheme(.dark)
}
#endif

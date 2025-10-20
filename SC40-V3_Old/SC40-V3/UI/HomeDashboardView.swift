// Main hub with nav to Session/Performance/Combine
import SwiftUI

struct HomeDashboardView: View {
    @State private var isMenuOpen = false
    @State private var showPerformance = false
    @State private var showTraining = false
    
    // Mock user info
    let athleteName = "John Doe"
    let currentLevel = "Intermediate"
    let nextMilestone = "40-Yard Test in 12 Days"
    
    // Mock highlights
    let highlights: [(icon: String, title: String, value: String, color: Color)] = [
        ("bolt.fill", "Best 40-Yard", "4.65s", .green),
        ("figure.run", "Acceleration", "1.78s (10yd)", .blue),
        ("speedometer", "Max Velocity", "21.2 mph (US)", .orange),
        ("flame.fill", "Consistency", "5/6 sessions", .red)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Welcome Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back,")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            Text(athleteName)
                                .foregroundColor(.white)
                                .font(.title)
                                .bold()
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        // Today’s Workout Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Workout")
                                .foregroundColor(.white)
                                .font(.headline)
                            Text("6×20yd Acceleration Sprints")
                                .foregroundColor(.green)
                                .font(.subheadline)
                            Button(action: { showTraining = true }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Start on Watch")
                                        .bold()
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.2)))
                        .padding(.horizontal)
                        // Performance Highlights Grid
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Performance Highlights")
                                .foregroundColor(.white)
                                .font(.headline)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(highlights, id: \.title) { item in
                                    VStack(spacing: 6) {
                                        Image(systemName: item.icon)
                                            .foregroundColor(item.color)
                                            .font(.title2)
                                        Text(item.title)
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                        Text(item.value)
                                            .foregroundColor(.white)
                                            .bold()
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 80)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.2)))
                                }
                            }
                        }
                        .padding(.horizontal)
                        // Next Milestone
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Next Milestone")
                                .foregroundColor(.white)
                                .font(.headline)
                            Text(nextMilestone)
                                .foregroundColor(.green)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.2)))
                        .padding(.horizontal)
                        // Quick Actions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Actions")
                                .foregroundColor(.white)
                                .font(.headline)
                            HStack {
                                Button(action: { showPerformance = true }) {
                                    HStack {
                                        Image(systemName: "chart.bar.fill")
                                        Text("Performance")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                Button(action: { showTraining = true }) {
                                    HStack {
                                        Image(systemName: "figure.run")
                                        Text("Training Log")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                        Spacer(minLength: 50)
                    }
                }
                // Hamburger Menu
                if isMenuOpen {
                    VStack {
                        HStack {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Menu")
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.white)
                                Text("Profile")
                                    .foregroundColor(.gray)
                                Text("Settings")
                                    .foregroundColor(.gray)
                                Text("Logout")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .frame(maxWidth: 200, alignment: .leading)
                            .background(Color.gray.opacity(0.9))
                            .cornerRadius(16)
                            Spacer()
                        }
                        Spacer()
                    }
                    .transition(.move(edge: .leading))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { withAnimation { isMenuOpen.toggle() } }) {
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(.white)
                    }
                }
            }
            // Navigation destinations
            .sheet(isPresented: $showPerformance) {
                PerformanceView()
            }
        }
    }
}

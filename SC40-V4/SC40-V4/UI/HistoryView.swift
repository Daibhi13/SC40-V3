import SwiftUI

struct HistoryView: View {
    let sessions: [TrainingSession]
    let userProfile: UserProfile
    
    // Pre-computed stable data to prevent flashing
    private let completedSessions: [TrainingSession]
    private let sortedSessions: [TrainingSession]
    
    init(sessions: [TrainingSession], userProfile: UserProfile) {
        self.sessions = sessions
        self.userProfile = userProfile
        
        // Pre-filter and sort completed sessions to prevent UI updates
        let completed = sessions.filter { $0.isCompleted }
        
        // Create stable sorted array
        self.completedSessions = completed
        self.sortedSessions = completed.sorted { (a, b) in
            if a.week == b.week {
                return a.day > b.day // Most recent first
            } else {
                return a.week > b.week // Most recent week first
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.95),
                        Color.blue.opacity(0.3),
                        Color.purple.opacity(0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Summary Header
                    ProgressSummaryView(completedSessions: completedSessions, userProfile: userProfile)
                        .padding(.top, 8)
                    
                    // Session History List
                    if sortedSessions.isEmpty {
                        EmptyHistoryView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(sortedSessions, id: \.id) { session in
                                    SessionHistoryCard(session: session)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Training History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Progress Summary View

struct ProgressSummaryView: View {
    let completedSessions: [TrainingSession]
    let userProfile: UserProfile
    
    private var totalSessions: Int { completedSessions.count }
    private var personalBest: Double {
        // Use the personal best from UserProfile instead of sessions
        userProfile.personalBests["40yd"] ?? userProfile.baselineTime
    }
    private var lastWeekCompleted: Int? {
        completedSessions.map { $0.week }.max()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Training Progress")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                ProgressStat(
                    title: "Sessions",
                    value: "\(totalSessions)",
                    icon: "figure.run",
                    color: .blue
                )
                
                ProgressStat(
                    title: "Current PB",
                    value: String(format: "%.2fs", personalBest),
                    icon: "stopwatch",
                    color: .green
                )
                
                ProgressStat(
                    title: "Week",
                    value: lastWeekCompleted != nil ? "\(lastWeekCompleted!)" : "1",
                    icon: "calendar",
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

struct ProgressStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Session History Card

struct SessionHistoryCard: View {
    let session: TrainingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(session.week), Day \(session.day)")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Text(session.type)
                        .font(.subheadline)
                        .foregroundColor(.blue.opacity(0.8))
                }
                
                Spacer()
                
                if let date = session.completionDate {
                    Text(DateFormatter.sessionDate.string(from: date))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Sprint Results
            if !session.sprintTimes.isEmpty {
                SprintResultsView(session: session)
            }
            
            // Session Conditions
            SessionConditionsView(session: session)
            
            // Focus and Notes
            VStack(alignment: .leading, spacing: 8) {
                if !session.focus.isEmpty {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.yellow)
                        Text("Focus: \(session.focus)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                if let sessionNotes = session.sessionNotes, !sessionNotes.isEmpty {
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .foregroundColor(.green)
                        Text(sessionNotes)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Sprint Results View

struct SprintResultsView: View {
    let session: TrainingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "stopwatch.fill")
                    .foregroundColor(.green)
                Text("Sprint Times")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(Array(session.sprintTimes.enumerated()), id: \.offset) { index, time in
                    VStack(spacing: 2) {
                        Text("Run \(index + 1)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(String(format: "%.2fs", time))
                            .font(.subheadline.bold())
                            .foregroundColor(time == session.personalBest ? .yellow : .white)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
            
            // Best/Average Summary
            if let best = session.personalBest, let avg = session.averageTime {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Best: \(String(format: "%.2fs", best))")
                            .font(.caption.bold())
                            .foregroundColor(.yellow)
                        
                        Text("Avg: \(String(format: "%.2fs", avg))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    if let rpe = session.rpe {
                        VStack(alignment: .trailing) {
                            Text("RPE")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("\(rpe)/10")
                                .font(.caption.bold())
                                .foregroundColor(rpeColor(rpe))
                        }
                    }
                }
            }
        }
    }
    
    private func rpeColor(_ rpe: Int) -> Color {
        switch rpe {
        case 1...3: return .green
        case 4...6: return .yellow
        case 7...8: return .orange
        case 9...10: return .red
        default: return .white
        }
    }
}

// MARK: - Session Conditions View

struct SessionConditionsView: View {
    let session: TrainingSession
    
    var body: some View {
        HStack(spacing: 16) {
            // Weather
            if let weather = session.weatherCondition {
                HStack(spacing: 4) {
                    Image(systemName: weatherIcon(weather))
                        .foregroundColor(.cyan)
                    Text(weather)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Temperature
            if let temp = session.temperature {
                HStack(spacing: 4) {
                    Image(systemName: "thermometer")
                        .foregroundColor(.orange)
                    Text("\(Int(temp))°C")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // Location
            if let location = session.location {
                HStack(spacing: 4) {
                    Image(systemName: "location")
                        .foregroundColor(.purple)
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
        }
    }
    
    private func weatherIcon(_ weather: String) -> String {
        switch weather.lowercased() {
        case "clear", "sunny": return "sun.max"
        case "cloudy": return "cloud"
        case "windy": return "wind"
        case "rain", "rainy": return "cloud.rain"
        default: return "cloud.sun"
        }
    }
}

// MARK: - Empty History View

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Training History Yet")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("Complete your first training session to see your progress here!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                Text("After each session, you'll see:")
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.9))
                
                VStack(alignment: .leading, spacing: 8) {
                    HistoryFeatureRow(icon: "stopwatch", text: "Sprint times and personal bests")
                    HistoryFeatureRow(icon: "cloud.sun", text: "Weather conditions")
                    HistoryFeatureRow(icon: "location", text: "Training location")
                    HistoryFeatureRow(icon: "note.text", text: "Session notes and insights")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct HistoryFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let sessionDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

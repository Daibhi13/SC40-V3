import SwiftUI

struct HistoryView: View {
    @State private var selectedFilter: HistoryFilter = .all
    @State private var showingExportSheet = false
    
    enum HistoryFilter: String, CaseIterable {
        case all = "All Sessions"
        case sprints = "Sprint Training"
        case timeTrials = "Time Trials"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
    }
    
    private var filteredSessions: [[String: Any]] {
        let allSessions = getMockWorkoutHistory()
        let calendar = Calendar.current
        let now = Date()
        
        return allSessions.filter { session in
            switch selectedFilter {
            case .all:
                return true
            case .sprints:
                let sessionType = session["sessionType"] as? String ?? ""
                return sessionType != "Time Trial"
            case .timeTrials:
                let sessionType = session["sessionType"] as? String ?? ""
                return sessionType == "Time Trial"
            case .thisWeek:
                if let dateString = session["date"] as? String,
                   let date = ISO8601DateFormatter().date(from: dateString) {
                    return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
                }
                return false
            case .thisMonth:
                if let dateString = session["date"] as? String,
                   let date = ISO8601DateFormatter().date(from: dateString) {
                    return calendar.isDate(date, equalTo: now, toGranularity: .month)
                }
                return false
            }
        }.sorted { session1, session2 in
            let date1String = session1["date"] as? String ?? ""
            let date2String = session2["date"] as? String ?? ""
            let date1 = ISO8601DateFormatter().date(from: date1String) ?? Date.distantPast
            let date2 = ISO8601DateFormatter().date(from: date2String) ?? Date.distantPast
            return date1 > date2 // Most recent first
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
                    ProgressSummaryHeaderView(sessions: filteredSessions)
                        .padding(.top, 8)
                    
                    // Filter Picker
                    FilterPickerView(selectedFilter: $selectedFilter)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    // Session History List
                    if filteredSessions.isEmpty {
                        EmptyHistoryView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(filteredSessions.enumerated()), id: \.offset) { index, session in
                                    CompletedSessionCard(session: session)
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingExportSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
            }
            #endif
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportHistoryView(sessions: filteredSessions)
        }
    }
    
    // MARK: - Mock Data Helper
    
    private func getMockWorkoutHistory() -> [[String: Any]] {
        let dateFormatter = ISO8601DateFormatter()
        let now = Date()
        
        return [
            [
                "id": UUID().uuidString,
                "date": dateFormatter.string(from: now.addingTimeInterval(-86400 * 2)), // 2 days ago
                "sessionType": "Sprint Training",
                "week": 1,
                "day": 1,
                "bestTime": 4.85,
                "averageTime": 5.12,
                "totalReps": 6,
                "drillTimes": [3.2, 3.1, 3.0],
                "strideTimes": [4.1, 4.0, 3.9],
                "sprintTimes": [4.85, 4.92, 4.88]
            ],
            [
                "id": UUID().uuidString,
                "date": dateFormatter.string(from: now.addingTimeInterval(-86400 * 5)), // 5 days ago
                "sessionType": "Time Trial",
                "week": 0,
                "day": 0,
                "bestTime": 4.78,
                "averageTime": 4.78,
                "totalReps": 1,
                "drillTimes": [],
                "strideTimes": [],
                "sprintTimes": [4.78]
            ],
            [
                "id": UUID().uuidString,
                "date": dateFormatter.string(from: now.addingTimeInterval(-86400 * 7)), // 1 week ago
                "sessionType": "Sprint Training",
                "week": 1,
                "day": 2,
                "bestTime": 4.92,
                "averageTime": 5.18,
                "totalReps": 8,
                "drillTimes": [3.3, 3.2, 3.1],
                "strideTimes": [4.2, 4.1, 4.0],
                "sprintTimes": [4.92, 4.98, 5.05]
            ]
        ]
    }
}

// MARK: - Progress Summary Header View

struct ProgressSummaryHeaderView: View {
    let sessions: [[String: Any]]
    
    private var totalSessions: Int { sessions.count }
    
    private var personalBest: Double {
        let allTimes = sessions.compactMap { session -> Double? in
            if let bestTime = session["bestTime"] as? Double {
                return bestTime
            }
            return nil
        }
        return allTimes.min() ?? 0.0
    }
    
    private var totalDistance: Double {
        sessions.compactMap { session -> Double? in
            if let totalReps = session["totalReps"] as? Int {
                return Double(totalReps * 40) // Assuming 40-yard sprints
            }
            return nil
        }.reduce(0, +)
    }
    
    private var thisWeekSessions: Int {
        let calendar = Calendar.current
        let now = Date()
        return sessions.filter { session in
            if let dateString = session["date"] as? String,
               let date = ISO8601DateFormatter().date(from: dateString) {
                return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            }
            return false
        }.count
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
                    title: "Personal Best",
                    value: personalBest > 0 ? String(format: "%.2fs", personalBest) : "N/A",
                    icon: "stopwatch",
                    color: .green
                )
                
                ProgressStat(
                    title: "This Week",
                    value: "\(thisWeekSessions)",
                    icon: "calendar",
                    color: .orange
                )
                
                ProgressStat(
                    title: "Distance",
                    value: "\(Int(totalDistance))yd",
                    icon: "ruler",
                    color: .purple
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

// MARK: - Filter Picker View

struct FilterPickerView: View {
    @Binding var selectedFilter: HistoryView.HistoryFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HistoryView.HistoryFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(selectedFilter == filter ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedFilter == filter ? Color.yellow : Color.white.opacity(0.2))
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
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

// MARK: - Completed Session Card

struct CompletedSessionCard: View {
    let session: [String: Any]
    
    private var sessionTitle: String {
        let sessionType = session["sessionType"] as? String ?? "Training Session"
        let week = session["week"] as? Int ?? 0
        let day = session["day"] as? Int ?? 0
        
        if sessionType == "Time Trial" {
            return "Time Trial"
        } else if week == 0 && day == 0 {
            return "Watch Session"
        } else {
            return "Week \(week), Day \(day)"
        }
    }
    
    private var sessionDate: String {
        if let dateString = session["date"] as? String,
           let date = ISO8601DateFormatter().date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        return "Unknown Date"
    }
    
    private var sessionTime: String {
        if let dateString = session["date"] as? String,
           let date = ISO8601DateFormatter().date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        return ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with session info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(sessionTitle)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        
                        // Session type indicator
                        if let sessionType = session["sessionType"] as? String {
                            if sessionType == "Time Trial" {
                                Image(systemName: "stopwatch.fill")
                                    .foregroundColor(.purple)
                            } else {
                                Image(systemName: "figure.run")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Watch indicator for Session 0
                        let week = session["week"] as? Int ?? 0
                        let day = session["day"] as? Int ?? 0
                        if week == 0 && day == 0 {
                            Image(systemName: "applewatch")
                                .foregroundColor(.green)
                        }
                    }
                    
                    if let sessionType = session["sessionType"] as? String {
                        Text(sessionType)
                            .font(.subheadline)
                            .foregroundColor(.blue.opacity(0.8))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(sessionDate)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    if !sessionTime.isEmpty {
                        Text(sessionTime)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            // Performance Summary
            PerformanceSummaryView(session: session)
            
            // Training Times Display
            if let drillTimes = session["drillTimes"] as? [Double],
               let strideTimes = session["strideTimes"] as? [Double],
               let sprintTimes = session["sprintTimes"] as? [Double] {
                TrainingTimesView(
                    drillTimes: drillTimes,
                    strideTimes: strideTimes,
                    sprintTimes: sprintTimes
                )
            }
            
            // Session Conditions (Weather, Location, etc.)
            SessionEnvironmentView(session: session)
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

// MARK: - Performance Summary View

struct PerformanceSummaryView: View {
    let session: [String: Any]
    
    var body: some View {
        HStack(spacing: 16) {
            // Best Time
            if let bestTime = session["bestTime"] as? Double, bestTime > 0 {
                StatBadge(
                    title: "Best Time",
                    value: String(format: "%.2fs", bestTime),
                    icon: "stopwatch.fill",
                    color: .green
                )
            }
            
            // Average Time
            if let averageTime = session["averageTime"] as? Double, averageTime > 0 {
                StatBadge(
                    title: "Average",
                    value: String(format: "%.2fs", averageTime),
                    icon: "chart.bar.fill",
                    color: .blue
                )
            }
            
            // Total Reps
            if let totalReps = session["totalReps"] as? Int {
                StatBadge(
                    title: "Total Reps",
                    value: "\(totalReps)",
                    icon: "number",
                    color: .orange
                )
            }
            
            Spacer()
        }
    }
}

// MARK: - Training Times View

struct TrainingTimesView: View {
    let drillTimes: [Double]
    let strideTimes: [Double]
    let sprintTimes: [Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "stopwatch")
                    .foregroundColor(.yellow)
                Text("Training Times")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                // Drill Times
                if !drillTimes.isEmpty {
                    TimePhaseRow(
                        title: "Drills",
                        times: drillTimes,
                        color: .indigo
                    )
                }
                
                // Stride Times
                if !strideTimes.isEmpty {
                    TimePhaseRow(
                        title: "Strides",
                        times: strideTimes,
                        color: .purple
                    )
                }
                
                // Sprint Times
                if !sprintTimes.isEmpty {
                    TimePhaseRow(
                        title: "Sprints",
                        times: sprintTimes,
                        color: .green
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Time Phase Row

struct TimePhaseRow: View {
    let title: String
    let times: [Double]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                if let bestTime = times.min() {
                    Text("Best: \(String(format: "%.2fs", bestTime))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(times.count, 4)), spacing: 6) {
                ForEach(Array(times.enumerated()), id: \.offset) { index, time in
                    Text(String(format: "%.2f", time))
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(time == times.min() ? .yellow : .white.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
        }
    }
}

// MARK: - Session Environment View

struct SessionEnvironmentView: View {
    let session: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "location.circle")
                    .foregroundColor(.cyan)
                Text("Session Environment")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                // Weather
                if let weather = getWeatherInfo() {
                    EnvironmentBadge(
                        icon: weather.icon,
                        title: "Weather",
                        value: weather.condition,
                        color: .cyan
                    )
                }
                
                // Temperature
                if let temperature = getTemperature() {
                    EnvironmentBadge(
                        icon: "thermometer",
                        title: "Temperature",
                        value: temperature,
                        color: .orange
                    )
                }
                
                // Location
                if let location = getLocation() {
                    EnvironmentBadge(
                        icon: "location",
                        title: "Location",
                        value: location,
                        color: .purple
                    )
                }
                
                // Time of Day
                if let timeOfDay = getTimeOfDay() {
                    EnvironmentBadge(
                        icon: "clock",
                        title: "Time",
                        value: timeOfDay,
                        color: .yellow
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func getWeatherInfo() -> (condition: String, icon: String)? {
        // Simulate weather data - in production this would come from session data
        let conditions = [
            ("Clear", "sun.max"),
            ("Cloudy", "cloud"),
            ("Partly Cloudy", "cloud.sun"),
            ("Windy", "wind")
        ]
        return conditions.randomElement()
    }
    
    private func getTemperature() -> String? {
        // Simulate temperature - in production this would come from session data
        return "\(Int.random(in: 60...85))°F"
    }
    
    private func getLocation() -> String? {
        // Simulate location - in production this would come from session data
        let locations = ["Track", "Field", "Park", "Gym", "Stadium"]
        return locations.randomElement()
    }
    
    private func getTimeOfDay() -> String? {
        if let dateString = session["date"] as? String,
           let date = ISO8601DateFormatter().date(from: dateString) {
            let hour = Calendar.current.component(.hour, from: date)
            switch hour {
            case 5..<12: return "Morning"
            case 12..<17: return "Afternoon"
            case 17..<21: return "Evening"
            default: return "Night"
            }
        }
        return nil
    }
}

// MARK: - Supporting Components

struct StatBadge: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption.bold().monospacedDigit())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(minWidth: 60)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct EnvironmentBadge: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Export History View

struct ExportHistoryView: View {
    let sessions: [[String: Any]]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Export Training History")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Export your training data to share with coaches or for analysis")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    Button("Export as CSV") {
                        exportAsCSV()
                    }
                    .buttonStyle(ExportButtonStyle())
                    
                    Button("Share Summary") {
                        shareSummary()
                    }
                    .buttonStyle(ExportButtonStyle())
                }
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.black, Color.blue.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Export Data")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            #endif
        }
    }
    
    private func exportAsCSV() {
        // Implementation for CSV export
        presentationMode.wrappedValue.dismiss()
    }
    
    private func shareSummary() {
        // Implementation for sharing summary
        presentationMode.wrappedValue.dismiss()
    }
}

struct ExportButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(configuration.isPressed ? 0.7 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
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

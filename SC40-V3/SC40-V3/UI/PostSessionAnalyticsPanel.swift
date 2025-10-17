import SwiftUI

struct PostSessionAnalyticsPanel: View {
    var session: TrainingSession
    var personalBests: [String: Double] {
        [
            "reaction": 0.18,
            "acceleration": 1.60,
            "maxVelocity": 10.2,
            "endurance": 6.0
        ]
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Session Breakdown")
                .font(.title3.bold())
                .foregroundColor(.brandPrimary)
            HStack(spacing: 18) {
                MetricCard(title: "Reaction", value: String(format: "%.2fs", 0.21), color: .brandTertiary)
                MetricCard(title: "Acceleration", value: String(format: "%.2fs", 1.65), color: .brandTertiary)
                MetricCard(title: "Max Velocity", value: String(format: "%.1f mph", 21.2), color: .brandTertiary)
                MetricCard(title: "Endurance", value: "Strong", color: .brandPrimary)
            }
            .padding(.bottom, 8)
            VStack(alignment: .leading, spacing: 6) {
                Text("Trends & Insights")
                    .font(.headline)
                    .foregroundColor(.brandSecondary)
                Text("You improved 2.5% over last week.")
                    .foregroundColor(.green)
                Text("Your reaction time is in the top 10% of users.")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.brandAccent.opacity(0.13))
        .cornerRadius(14)
    }
}

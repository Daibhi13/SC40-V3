import SwiftUI

struct KeyMetricsStrip: View {
    let profile: UserProfile
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                MetricItem(
                    value: String(format: "%.2f", profile.baselineTime),
                    label: "40yd Dash",
                    systemImage: "timer"
                )
                
                MetricItem(
                    value: "\(profile.sessions.count)",
                    label: "Sessions",
                    systemImage: "flame.fill"
                )
                
                MetricItem(
                    value: "\(profile.consistencyScore)%",
                    label: "Consistency",
                    systemImage: "chart.line.uptrend.xyaxis"
                )
                
                MetricItem(
                    value: "\(profile.streakDays)",
                    label: "Day Streak",
                    systemImage: "flame"
                )
            }
            .padding(.horizontal)
        }
    }
}

private struct MetricItem: View {
    let value: String
    let label: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 80)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct KeyMetricsStrip_Previews: PreviewProvider {
    static var previews: some View {
        let profile = UserProfile()
        return KeyMetricsStrip(profile: profile)
            .previewLayout(.sizeThatFits)
    }
}

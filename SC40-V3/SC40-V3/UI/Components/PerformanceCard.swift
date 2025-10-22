import SwiftUI

struct PerformanceCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        PerformanceCard(
            title: "Best Time",
            value: "4.32s",
            icon: "trophy.fill",
            color: Color(red: 1.0, green: 0.8, blue: 0.0)
        )
        
        PerformanceCard(
            title: "Average",
            value: "4.85s",
            icon: "chart.bar.fill",
            color: Color.blue
        )
        
        PerformanceCard(
            title: "Total Sprints",
            value: "12",
            icon: "bolt.fill",
            color: Color.green
        )
    }
    .padding()
    .background(Color.black)
}

import SwiftUI

struct NavigationActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
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
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 12) {
        NavigationActionCard(
            title: "View History",
            subtitle: "See all your training sessions",
            icon: "clock.arrow.circlepath",
            color: Color.purple
        ) {
            print("Navigate to History")
        }
        
        NavigationActionCard(
            title: "Advanced Analytics",
            subtitle: "Detailed performance insights",
            icon: "chart.line.uptrend.xyaxis",
            color: Color.orange
        ) {
            print("Navigate to Analytics")
        }
        
        NavigationActionCard(
            title: "Share Performance",
            subtitle: "Share your results with teammates",
            icon: "square.and.arrow.up",
            color: Color.cyan
        ) {
            print("Share Performance")
        }
    }
    .padding()
    .background(Color.black)
}

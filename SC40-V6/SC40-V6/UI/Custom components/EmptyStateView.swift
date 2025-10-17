import SwiftUI

/// Reusable empty state view for when there's no data to display
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.1),
                                Color.purple.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(.blue.opacity(0.6))
            }
            
            // Title
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            // Action Button (if provided)
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.shared.medium()
                    action()
                }) {
                    HStack {
                        Text(actionTitle)
                            .font(.headline)
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Predefined Empty States

extension EmptyStateView {
    /// Empty state for when no workouts are available
    static func noWorkouts(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "figure.run",
            title: "No Workouts Yet",
            message: "Complete your onboarding to generate your personalized 12-week training program.",
            actionTitle: "Get Started",
            action: action
        )
    }
    
    /// Empty state for when no sessions are found
    static func noSessions() -> EmptyStateView {
        EmptyStateView(
            icon: "calendar.badge.exclamationmark",
            title: "No Sessions Available",
            message: "Your training sessions will appear here once your program is generated.",
            actionTitle: nil,
            action: nil
        )
    }
    
    /// Empty state for leaderboard with no data
    static func noLeaderboardData(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "trophy",
            title: "No Rankings Yet",
            message: "Be the first to post your time! Complete a workout and opt-in to the leaderboard to see your ranking.",
            actionTitle: "Start Training",
            action: action
        )
    }
    
    /// Empty state for news feed
    static func noNews(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "newspaper",
            title: "No News Available",
            message: "We couldn't load the latest sprint news. Check your internet connection and try again.",
            actionTitle: "Retry",
            action: action
        )
    }
    
    /// Empty state for workout history
    static func noHistory(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "clock.arrow.circlepath",
            title: "No Workout History",
            message: "Your completed workouts will appear here. Start your first training session to begin tracking your progress!",
            actionTitle: "View Training Plan",
            action: action
        )
    }
    
    /// Empty state for personal bests
    static func noPersonalBests(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "star.fill",
            title: "No Personal Bests Yet",
            message: "Complete workouts and track your times to see your personal records here.",
            actionTitle: "Start Training",
            action: action
        )
    }
    
    /// Empty state for search results
    static func noSearchResults(searchTerm: String) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "We couldn't find anything matching \"\(searchTerm)\". Try a different search term.",
            actionTitle: nil,
            action: nil
        )
    }
    
    /// Empty state for offline mode
    static func offline(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "No Internet Connection",
            message: "Some features require an internet connection. Please check your connection and try again.",
            actionTitle: "Retry",
            action: action
        )
    }
    
    /// Empty state for GPS issues
    static func noGPS(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "location.slash",
            title: "GPS Not Available",
            message: "GPS tracking is required for accurate timing. Please enable location services in Settings.",
            actionTitle: "Open Settings",
            action: action
        )
    }
}

// MARK: - Preview

#if DEBUG
struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmptyStateView.noWorkouts(action: {})
                .previewDisplayName("No Workouts")
            
            EmptyStateView.noLeaderboardData(action: {})
                .previewDisplayName("No Leaderboard")
            
            EmptyStateView.noNews(action: {})
                .previewDisplayName("No News")
            
            EmptyStateView.offline(action: {})
                .previewDisplayName("Offline")
        }
    }
}
#endif

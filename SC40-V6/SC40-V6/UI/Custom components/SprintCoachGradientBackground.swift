import SwiftUI

/// Premium gradient background matching Sprint Coach 40 design
struct SprintCoachGradientBackground: View {
    var body: some View {
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
    }
}

/// Alternative darker gradient for certain views
struct SprintCoachDarkGradientBackground: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 0.0),
                .init(color: Color(red: 0.1, green: 0.2, blue: 0.35), location: 0.4),
                .init(color: Color(red: 0.15, green: 0.25, blue: 0.45), location: 0.6),
                .init(color: Color(red: 0.2, green: 0.15, blue: 0.35), location: 0.8),
                .init(color: Color(red: 0.1, green: 0.05, blue: 0.25), location: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea(.all)
    }
}

#Preview {
    SprintCoachGradientBackground()
}

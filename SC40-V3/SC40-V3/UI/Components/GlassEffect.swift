import SwiftUI

extension View {
    func glassEffect(
        blurRadius: CGFloat = 24,
        opacity: Double = 0.92
    ) -> some View {
        self
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.18, green: 0.22, blue: 0.32),
                        Color(red: 0.24, green: 0.29, blue: 0.45),
                        Color(red: 0.36, green: 0.44, blue: 0.74),
                        Color(red: 0.13, green: 0.17, blue: 0.28)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blur(radius: blurRadius)
                .opacity(opacity)
            )
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.10),
                        Color.clear,
                        Color.white.opacity(0.04)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blendMode(.plusLighter)
            )
    }
}

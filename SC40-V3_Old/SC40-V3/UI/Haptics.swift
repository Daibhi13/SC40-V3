import SwiftUI
#if os(iOS)
import UIKit

@MainActor
func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.impactOccurred()
}

@MainActor
func triggerSuccessHaptic() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
}
#else
@MainActor
func triggerHaptic(_ style: Int = 1) {
    // No haptics on non-iOS platforms
}

@MainActor
func triggerSuccessHaptic() {
    // No haptics on non-iOS platforms
}
#endif

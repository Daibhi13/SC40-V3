import Foundation
#if os(watchOS)
import WatchKit
#endif

/// Triggers haptic feedback on the Watch.
class HapticsManager {
    static func triggerHaptic() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #endif
    }
}

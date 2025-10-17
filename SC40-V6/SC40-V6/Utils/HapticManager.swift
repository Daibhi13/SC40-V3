import UIKit

/// Centralized haptic feedback manager for consistent tactile feedback throughout the app
@MainActor
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// Light impact - for subtle interactions (e.g., button hover, picker scroll)
    func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium impact - for standard interactions (e.g., button tap, toggle)
    func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact - for important interactions (e.g., workout start, milestone)
    func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Rigid impact - for firm interactions (e.g., error, stop)
    func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    /// Soft impact - for gentle interactions (e.g., swipe, scroll)
    func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification - for completed actions (e.g., workout complete, PR achieved)
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification - for cautionary actions (e.g., low battery, poor GPS)
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification - for failed actions (e.g., sync failed, invalid input)
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection changed - for picker/selector changes (e.g., tab switch, filter change)
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Complex Patterns
    
    /// Celebration pattern - for achievements and milestones
    func celebration() {
        DispatchQueue.main.async {
            self.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.light()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.light()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.medium()
                    }
                }
            }
        }
    }
    
    /// Countdown pattern - for workout countdown (3, 2, 1, GO!)
    func countdown(count: Int, completion: @escaping () -> Void) {
        guard count > 0 else {
            heavy()
            completion()
            return
        }
        
        medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.countdown(count: count - 1, completion: completion)
        }
    }
    
    /// Progress pattern - for incremental progress (e.g., loading, uploading)
    func progress() {
        light()
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    /// Add haptic feedback to button tap
    func hapticFeedback(_ style: HapticStyle = .medium) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                switch style {
                case .light: HapticManager.shared.light()
                case .medium: HapticManager.shared.medium()
                case .heavy: HapticManager.shared.heavy()
                case .soft: HapticManager.shared.soft()
                case .rigid: HapticManager.shared.rigid()
                case .selection: HapticManager.shared.selection()
                case .success: HapticManager.shared.success()
                case .warning: HapticManager.shared.warning()
                case .error: HapticManager.shared.error()
                }
            }
        )
    }
}

enum HapticStyle {
    case light, medium, heavy, soft, rigid
    case selection
    case success, warning, error
}

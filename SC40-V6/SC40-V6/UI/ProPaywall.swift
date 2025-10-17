import SwiftUI

struct ProPaywall: View {
    @AppStorage("isProUser") private var isProUser: Bool = false
    @Binding var showPaywall: Bool
    var onUnlock: () -> Void
    var body: some View {
        VStack(spacing: 32) {
            Text("Unlock Pro Features")
                .font(.largeTitle.bold())
                .foregroundColor(.brandPrimary)
            Text("Access Starter Pro and Advanced Analytics with a single upgrade.")
                .font(.body)
                .foregroundColor(.brandSecondary)
                .multilineTextAlignment(.center)
            Button(action: { isProUser = true; showPaywall = false; triggerSuccessHaptic(); onUnlock() }) {
                Text("Upgrade for $4.99/mo")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.brandPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .accessibilityLabel("Upgrade to Pro")
            .accessibilityHint("Unlocks Starter Pro and Advanced Analytics features")
        }
        .padding()
    }
}

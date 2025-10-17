import SwiftUI

struct SprintCoachProView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Sprint Coach Pro")
                    .font(.largeTitle.bold())
                    .foregroundColor(.brandPrimary)
                    .padding(.top)
                Text("The Ultimate Coaching App")
                    .font(.title2)
                    .foregroundColor(.brandTertiary)
                Text("Sprint Coach Pro is a dual-device platform designed for modern teams and institutions. Coaches can upload training sessions using the Sprint Coach Pro Coach app or via the web. Athletes access and complete these sessions remotely on their own devices, wherever they are.")
                    .font(.body)
                    .foregroundColor(.brandSecondary)
                VStack(alignment: .leading, spacing: 16) {
                    Label { Text("Remote Training: Athletes complete sessions from anywhere.").foregroundColor(.brandSecondary) } icon: { Image(systemName: "figure.run").foregroundColor(.brandPrimary) }
                    Label { Text("Coach Upload: Sessions created on the Coach app or web.").foregroundColor(.brandSecondary) } icon: { Image(systemName: "person.crop.rectangle").foregroundColor(.brandPrimary) }
                    Label { Text("Analytics: Both athletes and coaches get deep performance insights.").foregroundColor(.brandSecondary) } icon: { Image(systemName: "chart.bar.xaxis").foregroundColor(.brandPrimary) }
                    Label { Text("In-App Communication: Messaging (WhatsApp-style), Athlete Journal, and direct coach feedback coming soon.").foregroundColor(.brandSecondary) } icon: { Image(systemName: "bubble.left.and.bubble.right.fill").foregroundColor(.brandPrimary) }
                    Label { Text("Team & Institution Ready: Built for group management and scalable coaching.").foregroundColor(.brandSecondary) } icon: { Image(systemName: "person.3.fill").foregroundColor(.brandPrimary) }
                }
                .font(.body)
                .padding(.vertical)
                Text("Monetization")
                    .font(.title2.bold())
                    .foregroundColor(.brandPrimary)
                Text("Sprint Coach Pro is a premium, subscription-based platform. Unlock advanced analytics, unlimited remote sessions, and team management features. Perfect for professional coaches, clubs, and schools.")
                    .font(.body)
                    .foregroundColor(.brandSecondary)
                Button(action: {
                    // TODO: Add StoreKit2 purchase logic here
                }) {
                    Text("Subscribe to Sprint Coach Pro")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.brandPrimary)
                        .foregroundColor(.brandBackground)
                        .cornerRadius(16)
                        .shadow(color: .brandPrimary.opacity(0.3), radius: 6, x: 0, y: 2)
                }
                .padding(.top)
                Spacer()
            }
            .padding()
        }
        .background(Color.brandBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("Sprint Coach Pro")
    }
}

// MARK: - Preview
#if DEBUG
struct SprintCoachProView_Previews: PreviewProvider {
    static var previews: some View {
        SprintCoachProView()
    }
}
#endif

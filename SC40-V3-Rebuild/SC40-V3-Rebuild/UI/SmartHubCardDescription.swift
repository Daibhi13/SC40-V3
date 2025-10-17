import SwiftUI

struct SmartHubCardDescription: View {
    let description: String
    var body: some View {
        Text(description)
            .font(.body)
            .foregroundColor(.white.opacity(0.85))
    }
}

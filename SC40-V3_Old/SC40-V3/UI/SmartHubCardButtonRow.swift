import SwiftUI

struct SmartHubCardButtonRow: View {
    let buttonText: String
    var body: some View {
        HStack {
            Spacer()
            Button(action: {}) {
                Text(buttonText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                    .background(Color(.darkGray))
                    .cornerRadius(20)
            }
        }
    }
}

import SwiftUI

struct SmartHubCardTitle: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title2.bold())
            .foregroundColor(.white)
    }
}

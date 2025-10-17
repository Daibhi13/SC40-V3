import SwiftUI

struct SmartHubCardImage: View {
    let image: String
    var body: some View {
        Image(systemName: image)
            .resizable()
            .scaledToFit()
            .frame(height: 120)
            .foregroundColor(.white)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(16)
    }
}

#Preview {
    SmartHubCardImage(image: "bolt.fill")
}

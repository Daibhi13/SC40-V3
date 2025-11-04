import SwiftUI

struct QuickWinFeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16, weight: .semibold))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        QuickWinFeatureRow(icon: "checkmark.circle.fill", text: "Easy to follow", color: .green)
        QuickWinFeatureRow(icon: "checkmark.circle.fill", text: "Only 10 minutes", color: .green)
        QuickWinFeatureRow(icon: "checkmark.circle.fill", text: "Unlock first badge", color: .green)
    }
    .padding()
}

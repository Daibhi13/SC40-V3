import SwiftUI

struct SideMenuRow: View {
    let icon: String
    let label: String
    let color: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
                    .foregroundColor(color ?? Color(red: 1.0, green: 0.8, blue: 0.0))
                    .font(.system(size: 20, weight: .medium))

                Text(label)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

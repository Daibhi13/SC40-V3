import SwiftUI

struct SideMenuRow: View {
    let icon: String
    let label: String
    let color: Color?
    let action: (() -> Void)?

    init(icon: String, label: String, color: Color? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.label = label
        self.color = color
        self.action = action
    }

    var body: some View {
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
        .onTapGesture {
            action?()
        }
    }
}

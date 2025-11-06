import SwiftUI

struct MiniSessionChartView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Splits")
                .font(.caption2)
                .foregroundColor(.brandTertiary)
            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: 2) {
                    Capsule().fill(Color.brandPrimary).frame(width: 10, height: 30)
                    Capsule().fill(Color.brandSecondary).frame(width: 10, height: 50)
                    Capsule().fill(Color.brandAccent).frame(width: 10, height: 40)
                    Capsule().fill(Color.brandTertiary).frame(width: 10, height: 35)
                }
            }
            .frame(height: 55)
        }
        .padding(.top, 4)
    }
}

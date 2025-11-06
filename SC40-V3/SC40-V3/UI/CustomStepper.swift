import SwiftUI

struct CustomStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        HStack {
            Text("\(label): \(value)\(unit.isEmpty ? "" : " \u{2009}\(unit)")")
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .medium))
            Spacer()
            Button(action: { if value > range.lowerBound { value -= 1 } }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)
                    .shadow(radius: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 4)
            Button(action: { if value < range.upperBound { value += 1 } }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.green)
                    .shadow(radius: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 6)
    }
}

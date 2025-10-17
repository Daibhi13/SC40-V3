// Reusable record card
import SwiftUI

struct RecordCard: View {
    var recordTitle: String
    var recordValue: String
    var body: some View {
        ZStack {
            // Liquid glass background for RecordCard
            Canvas { context, size in
                // Multi-layer gradient
                let gradient = Gradient(colors: [
                    Color.brandAccent.opacity(0.7),
                    Color.brandSecondary.opacity(0.6),
                    Color.brandPrimary.opacity(0.5)
                ])
                context.fill(
                    Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 10),
                    with: .linearGradient(gradient,
                                        startPoint: CGPoint(x: 0, y: 0),
                                        endPoint: CGPoint(x: size.width, y: size.height))
                )
                
                // Glass overlay
                context.fill(
                    Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 10),
                    with: .color(Color.brandBackground.opacity(0.1))
                )
                
                // Glass reflection
                let reflectionPath = Path { path in
                    path.addEllipse(in: CGRect(
                        x: size.width * 0.2,
                        y: size.height * 0.1,
                        width: size.width * 0.4,
                        height: size.height * 0.3
                    ))
                }
                context.fill(reflectionPath, with: .color(Color.brandPrimary.opacity(0.1)))
                
                // Border
                context.stroke(
                    Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 10),
                    with: .color(.brandAccent.opacity(0.3)),
                    lineWidth: 1
                )
            }
            
            VStack {
                Text(recordTitle)
                    .font(.headline)
                    .foregroundColor(.brandPrimary)
                Text(recordValue)
                    .font(.largeTitle)
                    .foregroundColor(.brandSecondary)
            }
            .padding()
        }
    }
}

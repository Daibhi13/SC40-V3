import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Sprint Coach 40")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("Apple Watch")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("✅ Ready")
                    .font(.body)
                    .foregroundColor(.green)
            }
            .padding()
        }
    }
}

// MARK: - Canvas Previews

#if DEBUG
#Preview("1. Watch Content View") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("2. Simple Watch View") {
    DaySessionCardsWatchView()
        .preferredColorScheme(.dark)
}
#endif




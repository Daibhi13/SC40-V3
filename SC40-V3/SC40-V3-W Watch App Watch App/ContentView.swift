import SwiftUI

struct ContentView: View {
    var body: some View {
        ContentViewWatch()
    }
}

#if DEBUG
#Preview("ContentView") {
    ContentView()
        .preferredColorScheme(.dark)
}
#endif

import SwiftUI

struct EntryViewWatch_Simple: View {
    var body: some View {
        VStack {
            Text("Sprint Coach 40")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("Apple Watch")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("Ready")
                .font(.body)
                .foregroundColor(.green)
        }
        .padding()
    }
}

import SwiftUI

struct WelcomeViewWatch: View {
    @State private var name: String = ""
    @State private var showDictation = false
    var onContinue: (String) -> Void
    var body: some View {
        ZStack {
            Canvas { context, size in
                // Welcome screen liquid glass background
                let welcomeGradient = Gradient(colors: [
                    Color.black,
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.1)
                ])
                context.fill(Path(CGRect(origin: .zero, size: size)),
                           with: .linearGradient(welcomeGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
                
                // Floating welcome bubbles
                context.addFilter(.blur(radius: 12))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.1, y: size.height * 0.2, width: 25, height: 25)),
                           with: .color(Color.blue.opacity(0.20)))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.7, y: size.height * 0.6, width: 30, height: 30)),
                           with: .color(Color.purple.opacity(0.15)))
                
                // Gentle wave pattern
                let waveHeight: CGFloat = 6
                let waveLength = size.width / 2
                var wavePath = Path()
                wavePath.move(to: CGPoint(x: 0, y: size.height * 0.8))
                for x in stride(from: 0, through: size.width, by: 2) {
                    let y = size.height * 0.8 + waveHeight * sin((x / waveLength) * 2 * .pi)
                    wavePath.addLine(to: CGPoint(x: x, y: y))
                }
                wavePath.addLine(to: CGPoint(x: size.width, y: size.height))
                wavePath.addLine(to: CGPoint(x: 0, y: size.height))
                
                context.fill(wavePath, with: .color(Color.cyan.opacity(0.12)))
            }
            .ignoresSafeArea()
            VStack(spacing: 16) {
            // Sprint branding with icon
            HStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.title2)
                    .foregroundColor(.yellow)
                Text("SC40-V3")
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            
            Text("Sprint Training")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 4)
            
            Text("Ready, Sprinter?")
                .font(.title3)
                .foregroundColor(.white)
                .padding(.bottom, 2)
            
            Text("Enter your name to begin")
                .font(.caption2)
                .foregroundColor(.gray)
            Button(action: { showDictation = true }) {
                Label(name.isEmpty ? "Tap to Dictate Name" : name, systemImage: "mic.fill")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            .sheet(isPresented: $showDictation) {
                ZStack {
                    Canvas { context, size in
                        // Dictation modal background
                        let dictationGradient = Gradient(colors: [
                            Color.black,
                            Color.blue.opacity(0.2)
                        ])
                        context.fill(Path(CGRect(origin: .zero, size: size)),
                                   with: .linearGradient(dictationGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
                        
                        // Microphone visualization
                        context.fill(Path(ellipseIn: CGRect(x: size.width * 0.4, y: size.height * 0.3, width: 20, height: 20)),
                                   with: .color(Color.green.opacity(0.25)))
                    }
                    .ignoresSafeArea()
                    DictationInputView(text: $name)
                }
            }
            Button("Continue") {
                onContinue(name.isEmpty ? "User" : name)
            }
            .disabled(name.isEmpty)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(name.isEmpty ? Color.gray.opacity(0.3) : Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        }
    }
}

struct DictationInputView: View {
    @Binding var text: String
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack(spacing: 12) {
            Text("Dictate your name")
                .font(.headline)
            Button("Simulate Dictation: John") {
                text = "John"
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.red)
        }
        .padding()
    }
}

#Preview {
    WelcomeViewWatch { _ in }
}

import SwiftUI
import Combine
import WatchConnectivity
import AVFoundation

// Animated, branded splash screen for StarterProWatchView
struct SplashScreen: View {
    @State private var splashScale: CGFloat = 0.8
    @State private var splashOpacity: Double = 0.0
    var body: some View {
        ZStack {
            Canvas { context, size in
                // Liquid glass background with depth
                let gradient = Gradient(colors: [
                    BrandColorsWatch.background,
                    BrandColorsWatch.tertiary.opacity(0.18),
                    BrandColorsWatch.primary.opacity(0.05)
                ])
                context.fill(Path(CGRect(origin: .zero, size: size)), 
                           with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
                
                // Floating glass orb effect
                context.addFilter(.blur(radius: 20))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.1, y: size.height * 0.2, width: 60, height: 60)), 
                           with: .color(BrandColorsWatch.primary.opacity(0.15)))
                context.addFilter(.blur(radius: 15))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.7, y: size.height * 0.7, width: 40, height: 40)), 
                           with: .color(BrandColorsWatch.accent.opacity(0.20)))
            }
            .ignoresSafeArea()
            VStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(BrandColorsWatch.primary.opacity(0.13))
                        .frame(width: 120, height: 120)
                    Text("SC")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundColor(BrandColorsWatch.primary)
                        .shadow(color: BrandColorsWatch.tertiary.opacity(0.18), radius: 2, x: 0, y: 1)
                }
                .scaleEffect(splashScale)
                .opacity(splashOpacity)
                Text("Starts Coach")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .shadow(color: BrandColorsWatch.tertiary.opacity(0.18), radius: 1, x: 0, y: 1)
                    .padding(.top, 8)
                    .scaleEffect(splashScale)
                    .opacity(splashOpacity)
                Spacer()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) {
                    splashScale = 1.1
                    splashOpacity = 1.0
                }
            }
        }
    }
}


struct StarterProView: View {
    @State private var showSplash: Bool = true
    @State private var sets: Int = 10
    @State private var showSetsPicker: Bool = false
    @State private var restTime: Int = 180 // seconds
    @State private var showRestPicker: Bool = false
    @State private var restMinutes: Int = 3
    @State private var restSeconds: Int = 0
    @State private var isStarted: Bool = false
    @State private var showTimeTrial: Bool = false
    @State private var currentTimeString: String = StarterProView.getCurrentTimeString()
    @State private var sprintTimes: [Double] = []
    
    // Add state and helper for distance picker
    @State private var showDistancePicker: Bool = false
    @State private var distance: Int = 40
    private func distanceString() -> String { "\(distance) yd" }
    
    // Move helpers above their first use
    func restTimeString() -> String {
        String(format: "%d:%02d", restTime/60, restTime%60)
    }
    func totalTimeString() -> String {
        let totalSeconds = restTime * sets
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    @MainActor private static func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    private func startClockTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { @Sendable _ in
            Task { @MainActor in
                self.currentTimeString = StarterProView.getCurrentTimeString()
            }
        }
    }
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen()
            } else {
                mainContent
            }
        }
        .onAppear {
            if showSplash {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showSplash = false
                    }
                }
            }
        }
    }
    var mainContent: some View {
        ZStack {
            Canvas { context, size in
                // Sophisticated liquid glass background
                let mainGradient = Gradient(colors: [
                    BrandColorsWatch.background,
                    BrandColorsWatch.tertiary.opacity(0.18),
                    BrandColorsWatch.primary.opacity(0.08)
                ])
                context.fill(Path(CGRect(origin: .zero, size: size)),
                           with: .linearGradient(mainGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
                
                // Flowing wave effect for watch
                let waveHeight: CGFloat = 8
                let waveLength = size.width / 3
                let phase: CGFloat = 0.5 // Static phase for watch
                
                var wavePath = Path()
                wavePath.move(to: CGPoint(x: 0, y: size.height * 0.4))
                for x in stride(from: 0, through: size.width, by: 2) {
                    let y = size.height * 0.4 + waveHeight * sin((x / waveLength) * 2 * .pi + phase)
                    wavePath.addLine(to: CGPoint(x: x, y: y))
                }
                wavePath.addLine(to: CGPoint(x: size.width, y: size.height))
                wavePath.addLine(to: CGPoint(x: 0, y: size.height))
                
                context.fill(wavePath, with: .color(BrandColorsWatch.accent.opacity(0.12)))
                
                // Glass bubble effects
                context.addFilter(.blur(radius: 12))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.15, y: size.height * 0.25, width: 25, height: 25)),
                           with: .color(BrandColorsWatch.primary.opacity(0.18)))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.75, y: size.height * 0.65, width: 20, height: 20)),
                           with: .color(BrandColorsWatch.tertiary.opacity(0.15)))
            }
            .ignoresSafeArea()
            if showTimeTrial {
                TimeTrialWorkoutView(workoutVM: WorkoutWatchViewModel())
            } else {
                ScrollView(.vertical) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Time Trial")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(BrandColorsWatch.primary)
                        }
                        .padding(.top, 4)
                        Text("Total Time \(totalTimeString())")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(BrandColorsWatch.accent)
                            .padding(.bottom, 2)
                        // Distance Row
                        Button(action: { showDistancePicker = true }) {
                            HStack(spacing: 0) {
                                Text("Distance")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(BrandColorsWatch.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                                Text("\(distanceString())")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(BrandColorsWatch.primary)
                                    .frame(width: 60)
                            }
                            .padding(.vertical, 8)
                            .background(BrandColorsWatch.tertiary.opacity(0.10))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showDistancePicker) {
                            ZStack {
                                Canvas { context, size in
                                    // Picker modal background
                                    let modalGradient = Gradient(colors: [
                                        BrandColorsWatch.background,
                                        BrandColorsWatch.tertiary.opacity(0.18)
                                    ])
                                    context.fill(Path(CGRect(origin: .zero, size: size)),
                                               with: .linearGradient(modalGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
                                    
                                    // Subtle glass overlay
                                    context.fill(Path(ellipseIn: CGRect(x: size.width * 0.3, y: size.height * 0.2, width: 30, height: 30)),
                                               with: .color(BrandColorsWatch.primary.opacity(0.10)))
                                }
                                .ignoresSafeArea()
                                VStack {
                                    Text("Distance")
                                        .font(.headline)
                                        .foregroundColor(BrandColorsWatch.primary)
                                        .padding(.top)
                                    Spacer()
                                    Picker("Distance", selection: $distance) {
                                        ForEach([20, 30, 40, 50, 60, 100, 200], id: \ .self) { Text("\($0) yd").foregroundColor(BrandColorsWatch.secondary) }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    .clipped()
                                    .background(BrandColorsWatch.background.opacity(0.7))
                                    .cornerRadius(10)
                                    Spacer()
                                    Button("Done") { showDistancePicker = false }
                                        .font(.title3)
                                        .foregroundColor(BrandColorsWatch.primary)
                                        .padding(.bottom)
                                }
                            }
                        }
                        Button(action: { showSetsPicker = true }) {
                            HStack(spacing: 0) {
                                Text("Sets")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(BrandColorsWatch.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                                Text("\(sets)")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(BrandColorsWatch.primary)
                                    .frame(width: 40)
                            }
                            .padding(.vertical, 8)
                            .background(BrandColorsWatch.tertiary.opacity(0.10))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showSetsPicker) {
                            ZStack {
                                Canvas { context, size in
                                    // Picker modal background
                                    let modalGradient = Gradient(colors: [
                                        BrandColorsWatch.background,
                                        BrandColorsWatch.tertiary.opacity(0.18)
                                    ])
                                    context.fill(Path(CGRect(origin: .zero, size: size)),
                                               with: .linearGradient(modalGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
                                    
                                    // Subtle glass overlay
                                    context.fill(Path(ellipseIn: CGRect(x: size.width * 0.7, y: size.height * 0.6, width: 25, height: 25)),
                                               with: .color(BrandColorsWatch.accent.opacity(0.12)))
                                }
                                .ignoresSafeArea()
                                VStack {
                                    Text("Sets")
                                        .font(.headline)
                                        .foregroundColor(BrandColorsWatch.primary)
                                        .padding(.top)
                                    Spacer()
                                    Picker("Sets", selection: $sets) {
                                        ForEach(1...30, id: \ .self) { Text("\($0)").foregroundColor(BrandColorsWatch.secondary) }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    .clipped()
                                    .background(BrandColorsWatch.background.opacity(0.7))
                                    .cornerRadius(10)
                                    Spacer()
                                    Button("Done") { showSetsPicker = false }
                                        .font(.title3)
                                        .foregroundColor(BrandColorsWatch.primary)
                                        .padding(.bottom)
                                }
                            }
                        }
                        Button(action: {
                            restMinutes = restTime / 60
                            restSeconds = restTime % 60
                            showRestPicker = true
                        }) {
                            HStack(spacing: 0) {
                                Text("Rest")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(BrandColorsWatch.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                                Text(restTimeString())
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(BrandColorsWatch.primary)
                                    .frame(width: 60)
                            }
                            .padding(.vertical, 8)
                            .background(BrandColorsWatch.tertiary.opacity(0.10))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showRestPicker) {
                            ZStack {
                                Canvas { context, size in
                                    // Picker modal background
                                    let modalGradient = Gradient(colors: [
                                        BrandColorsWatch.background,
                                        BrandColorsWatch.tertiary.opacity(0.18)
                                    ])
                                    context.fill(Path(CGRect(origin: .zero, size: size)),
                                               with: .linearGradient(modalGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
                                    
                                    // Subtle glass overlay
                                    context.fill(Path(ellipseIn: CGRect(x: size.width * 0.2, y: size.height * 0.8, width: 35, height: 35)),
                                               with: .color(BrandColorsWatch.tertiary.opacity(0.15)))
                                }
                                .ignoresSafeArea()
                                VStack {
                                    Text("Rest")
                                        .font(.headline)
                                        .foregroundColor(BrandColorsWatch.primary)
                                        .padding(.top)
                                    Spacer()
                                    HStack(spacing: 0) {
                                        VStack(spacing: 2) {
                                            Text("min")
                                                .font(.caption2)
                                                .foregroundColor(BrandColorsWatch.secondary.opacity(0.7))
                                            Picker("Minutes", selection: $restMinutes) {
                                                ForEach(0...9, id: \ .self) { Text("\($0)").foregroundColor(BrandColorsWatch.secondary) }
                                            }
                                            .frame(width: 80)
                                            .clipped()
                                            .background(BrandColorsWatch.background.opacity(0.7))
                                            .cornerRadius(8)
                                        }
                                        VStack(spacing: 2) {
                                            Text("sec")
                                                .font(.caption2)
                                                .foregroundColor(BrandColorsWatch.secondary.opacity(0.7))
                                            Picker("Seconds", selection: $restSeconds) {
                                                ForEach(0...59, id: \ .self) { Text(String(format: "%02d", $0)).foregroundColor(BrandColorsWatch.secondary) }
                                            }
                                            .frame(width: 80)
                                            .clipped()
                                            .background(BrandColorsWatch.background.opacity(0.7))
                                            .cornerRadius(8)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    Spacer()
                                    Button("Done") {
                                        restTime = restMinutes * 60 + restSeconds
                                        showRestPicker = false
                                    }
                                        .font(.title3)
                                        .foregroundColor(BrandColorsWatch.primary)
                                        .padding(.bottom)
                                }
                            }
                        }
                        Spacer(minLength: 0)
                        Button(action: { showTimeTrial = true }) {
                            Label("Start Session", systemImage: "play.fill")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(BrandColorsWatch.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(BrandColorsWatch.primary)
                                .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding([.horizontal, .bottom])
                }
                .onAppear {
                    startClockTimer()
                }
            }
        }
    }
    func sendResultsToPhone() {
        let message: [String: Any] = [
            "type": "starterProResults",
            "date": Date().timeIntervalSince1970,
            "results": sprintTimes
        ]
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.activationState != .activated {
                session.activate()
            }
            if session.isReachable {
                session.sendMessage(message, replyHandler: nil) { error in
                    print("[Watch] Error sending results: \(error.localizedDescription)")
                }
            } else {
                print("[Watch] iPhone not reachable for results sync.")
            }
        }
    }
    
    @State private var isSprintStarting = false
    private let speechSynth = AVSpeechSynthesizer()
    
    private func speak(_ phrase: String) {
        let utterance = AVSpeechUtterance(string: phrase)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.48
        speechSynth.speak(utterance)
    }
    
    private func playOlympicBeep() {
        // Play Olympic-style beep sequence using system sounds and haptics
        print("🔊 Playing Olympic beep sequence")
        
        // Three short preparatory beeps
        WKInterfaceDevice.current().play(.click)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            WKInterfaceDevice.current().play(.click)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            WKInterfaceDevice.current().play(.click)
        }
        
        // Final start beep with haptic feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            WKInterfaceDevice.current().play(.start)
            WKInterfaceDevice.current().play(.notification)
        }
    }
    // Example: Call this function at the start of each sprint
    private func startSprintSequence() {
        isSprintStarting = true
        speak("Ready")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            speak("Set")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                speak("Go")
                playOlympicBeep()
                isSprintStarting = false
            }
        }
    }
}

// Listen for start session trigger from phone
class WatchSessionTriggerManager: NSObject, ObservableObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = WatchSessionTriggerManager()
    @Published var shouldStartSession: Bool = false
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let trigger = message["trigger"] as? String, trigger == "startSession" {
            DispatchQueue.main.async {
                self.shouldStartSession = true
            }
        }
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}

// For compatibility with old references
typealias StarterProWatchView = StarterProView

#Preview {
    StarterProView()
}

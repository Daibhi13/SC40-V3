import SwiftUI
import WatchKit
import AVFoundation

enum WorkoutModal: Identifiable {
    case summary, sprint, repLog
    
    var id: String {
        switch self {
        case .summary: return "summary"
        case .sprint: return "sprint"
        case .repLog: return "repLog"
        }
    }
}

struct MainWorkoutWatchView: View {
    @StateObject var workoutVM: WorkoutWatchViewModel
    @State private var activeModal: WorkoutModal?
    @State private var selectedBottomModuleLeft: BottomModuleType = .rest
    @State private var selectedBottomModuleRight: BottomModuleType = .split
    @State private var showSprintGraph = false
    @State private var colorTheme: ColorTheme = .apple
    @State private var tabSelection = 1 // 0: Control, 1: Main, 2: Music
    @State private var animateScale = false
    @State private var isSprintStarting = false
    private let speechSynth = AVSpeechSynthesizer()
    
    public init(workoutVM: WorkoutWatchViewModel) {
        _workoutVM = StateObject(wrappedValue: workoutVM)
    }
    
    private func speak(_ phrase: String) {
        // Use unified voice manager for consistent voice settings
        UnifiedVoiceManager.shared.speak(phrase)
        print("🔊 Speaking: \(phrase)")
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
    
    // MARK: - Top Row
    private var topStatsRow: some View {
        HStack(spacing: 4) {
            StatModuleView(icon: "heart.fill",
                           label: "BPM",
                           value: workoutVM.heartRateString,
                           color: .green,
                           theme: colorTheme)
            StatModuleView(icon: "ruler",
                           label: "YDS",
                           value: workoutVM.distanceRemainingString,
                           color: .white,
                           theme: colorTheme)
            StatModuleView(icon: "repeat",
                           label: "REP",
                           value: "\(workoutVM.currentRep)/\(workoutVM.totalReps)",
                           color: .accentColor,
                           theme: colorTheme)
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - Main Module
    private var mainModule: some View {
        VStack(spacing: 6) {
            if showSprintGraph {
                SprintGraphView(viewModel: workoutVM, theme: colorTheme)
                    .frame(height: 70)
            } else if workoutVM.isGPSPhase {
                // Trigger spoken feedback and starter pistol at the start of each GPS sprint/stride
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                    Text("GPS Stopwatch\n(Coming Soon)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 70)
                .onAppear {
                    if !isSprintStarting && workoutVM.isRunning {
                        startSprintSequence()
                    }
                }
                .accessibilityLabel("Sprint Timer")
                .accessibilityHint("Timer for your sprint. Spoken cues and starter pistol will play at the start.")
            } else {
                // Phase indicator
                Text(workoutVM.currentPhaseLabel.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                    .tracking(1.0)
                
                // Main timer display
                VStack(spacing: 2) {
                    Text(workoutVM.stopwatchTimeString)
                        .font(.system(size: 36, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("ELAPSED TIME")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { showSprintGraph.toggle() }
    }
    
    // MARK: - Bottom Row
    private var bottomStatsRow: some View {
        HStack(spacing: 6) {
            bottomModuleView(type: selectedBottomModuleLeft)
            bottomModuleView(type: selectedBottomModuleRight)
        }
    }
    
    private func bottomModuleView(type: BottomModuleType) -> some View {
        switch type {
        case .rest:
            return AnyView(RestTimerModuleView(restTime: workoutVM.restTimeString,
                                               progress: workoutVM.restProgress,
                                               theme: colorTheme))
        case .split:
            return AnyView(SplitTimeModuleView(avg: workoutVM.avgSplitString,
                                               last: workoutVM.lastSprintString,
                                               theme: colorTheme))
        case .pace:
            return AnyView(PaceModuleView(pace: workoutVM.paceString, theme: colorTheme))
        case .fatigue:
            return AnyView(FatigueModuleView(rpe: workoutVM.rpe, theme: colorTheme))
        case .leaderboard:
            return AnyView(LeaderboardModuleView(rank: workoutVM.leaderboardRank, theme: colorTheme))
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $tabSelection) {
                ControlWatchView(
                    selectedIndex: 0, 
                    workoutVM: workoutVM,
                    session: TrainingSession(
                        week: 1,
                        day: 1,
                        type: "Main Workout",
                        focus: "Sprint Training",
                        sprints: [SprintSet(distanceYards: 40, reps: 5, intensity: "max")],
                        accessoryWork: []
                    )
                )
                .tag(0)
                mainTabContent
                    .tag(1)
                MusicWatchView(
                    selectedIndex: 2,
                    session: TrainingSession(
                        week: 1,
                        day: 1,
                        type: "Main Workout",
                        focus: "Sprint Training",
                        sprints: [SprintSet(distanceYards: 40, reps: 5, intensity: "max")],
                        accessoryWork: []
                    )
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .onAppear { workoutVM.setupUltra2Features() }
        .fullScreenCover(item: $activeModal) { modal in
            switch modal {
            case .summary:
                RepLogSummaryFlowView(workoutVM: workoutVM, onDone: { activeModal = nil })
            case .sprint:
                SprintWatchView(viewModel: workoutVM, onDismiss: { activeModal = nil })
            case .repLog:
                RepLogWatchLiveView(
                    workoutVM: workoutVM,
                    horizontalTab: .constant(1),
                    isModal: true,
                    onDone: { activeModal = nil },
                    session: TrainingSession(
                        week: 1,
                        day: 1,
                        type: "Main Workout",
                        focus: "Sprint Training",
                        sprints: [SprintSet(distanceYards: 40, reps: 5, intensity: "max")],
                        accessoryWork: []
                    )
                )
            }
        }
    }
    
    // Main tab content with vertical drag gesture and animation
    private var mainTabContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                // Top stats row with proper spacing from status bar
                topStatsRow
                    .padding(.top, 8)
                
                Divider()
                    .background(Color.gray.opacity(0.4))
                    .padding(.horizontal, 8)
                
                // Main module with flexible spacing
                Spacer(minLength: 4)
                mainModule
                Spacer(minLength: 4)
                
                Divider()
                    .background(Color.gray.opacity(0.4))
                    .padding(.horizontal, 8)
                
                // Bottom stats row with proper spacing from bottom
                bottomStatsRow
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 4)
        }
        .scaleEffect(animateScale ? 0.96 : 1.0)
        .animation(.easeOut(duration: 0.18), value: animateScale)
        .gesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .local)
                .onEnded { value in
                    print("🔍 MainWorkout gesture: x=\(value.translation.width), y=\(value.translation.height)")
                    
                    let horizontal = abs(value.translation.width) > abs(value.translation.height)
                    
                    if !horizontal {
                        // Vertical swipes (prioritize these)
                        if value.translation.height > 8 {
                            // Swipe down - RepLogWatchLiveView
                            print("🔽 SWIPE DOWN DETECTED - showing RepLog")
                            withAnimation(.spring()) {
                                animateScale = true
                                WKInterfaceDevice.current().play(.click)
                                activeModal = .repLog
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                animateScale = false
                            }
                        } else if value.translation.height < -8 {
                            // Swipe up - SprintWatchView
                            print("🔼 SWIPE UP DETECTED - showing SprintView")
                            withAnimation(.spring()) {
                                animateScale = true
                                WKInterfaceDevice.current().play(.directionUp)
                                activeModal = .sprint
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                animateScale = false
                            }
                        }
                    } else if abs(value.translation.width) > 20 {
                        // Only handle horizontal swipes if they're significant
                        if value.translation.width > 20 {
                            // Swipe right - ControlWatchView
                            print("➡️ SWIPE RIGHT DETECTED - switching to Control tab")
                            withAnimation(.spring()) {
                                animateScale = true
                                WKInterfaceDevice.current().play(.click)
                                tabSelection = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                animateScale = false
                            }
                        } else if value.translation.width < -20 {
                            // Swipe left - MusicWatchView
                            print("⬅️ SWIPE LEFT DETECTED - switching to Music tab")
                            withAnimation(.spring()) {
                                animateScale = true
                                WKInterfaceDevice.current().play(.click)
                                tabSelection = 2
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                animateScale = false
                            }
                        }
                    }
                }
        )
    }
    // Example: Call this function at the start of each sprint
    private func startSprintSequence() {
        isSprintStarting = true
        let currentDistance = workoutVM.distanceRemainingString
        let repNumber = workoutVM.currentRep
        let totalReps = workoutVM.totalReps
        
        print("🏃‍♂️ Starting sprint sequence for rep \(repNumber)/\(totalReps) at \(currentDistance) yards")
        
        speak("Rep \(repNumber) of \(totalReps). \(currentDistance) yards.")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.speak("Ready")
            WKInterfaceDevice.current().play(.directionUp)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.speak("Set")
                WKInterfaceDevice.current().play(.directionUp)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.speak("Go")
                    self.playOlympicBeep()
                    
                    // Actually start the workout timer if needed
                    if !self.workoutVM.isRunning {
                        self.workoutVM.startRep()
                    }
                    
                    self.isSprintStarting = false
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum BottomModuleType: CaseIterable {
    case rest, split, pace, fatigue, leaderboard
    var displayName: String {
        switch self {
        case .rest: return "Rest"
        case .split: return "Split"
        case .pace: return "Pace"
        case .fatigue: return "Fatigue"
        case .leaderboard: return "Rank"
        }
    }
}

enum ColorTheme: CaseIterable {
    case apple, nike
    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .nike: return "Nike"
        }
    }
}

// MARK: - CircleSegment (move above for scope)
struct CircleSegment: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let glow: Bool
    var body: some View {
        Circle()
            .trim(from: CGFloat(startAngle.degrees/360), to: CGFloat(endAngle.degrees/360))
            .stroke(color, style: StrokeStyle(lineWidth: glow ? 10 : 7, lineCap: .round))
            .shadow(color: glow ? .green.opacity(0.7) : .clear, radius: glow ? 8 : 0)
            .rotationEffect(.degrees(-90))
    }
}

// MARK: - Phase Icon Label (for ring)
struct PhaseIconLabel: View {
    let icon: String
    let label: String
    let isActive: Bool
    let position: CGPoint
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isActive ? .accentColor : .secondary)
            Text(label)
                .font(.system(size: 8, weight: .regular))
                .foregroundColor(isActive ? .accentColor : .secondary)
        }
        .position(position)
    }
}

// MARK: - Circular Progress Ring with Phase Icons (refactored)
struct CircularPhaseProgressView: View {
    let phases: [WorkoutPhase]
    let currentPhase: Int
    let theme: ColorTheme
    let phaseIcons: [String] = ["flame.fill", "figure.walk", "figure.run", "pause.fill", "figure.cooldown"]
    let phaseLabels: [String] = ["Warmup", "Drills", "Sprint", "Rest", "Cooldown"]
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ringSegments(size: geo.size)
                phaseIconLabels(size: geo.size)
            }
        }
    }
    // Draw the colored ring segments
    func ringSegments(size: CGSize) -> some View {
        ForEach(0..<phases.count, id: \.self) { idx in
            ringSegment(idx: idx, size: size)
        }
    }
    // Helper for a single ring segment
    func ringSegment(idx: Int, size: CGSize) -> some View {
        let start = Double(idx) / Double(phases.count) * 360
        let end = Double(idx + 1) / Double(phases.count) * 360
        return CircleSegment(
            startAngle: .degrees(start),
            endAngle: .degrees(end),
            color: colorForPhase(idx: idx),
            glow: false
        )
        .frame(width: size.width, height: size.height)
    }
    // Draw the phase icons/labels
    func phaseIconLabels(size: CGSize) -> some View {
        ForEach(0..<phases.count, id: \.self) { idx in
            phaseIconLabel(idx: idx, size: size)
        }
    }
    // Helper for a single phase icon/label
    func phaseIconLabel(idx: Int, size: CGSize) -> some View {
        let angle = Double(idx) / Double(phases.count) * 2 * .pi - .pi/2
        let radius = size.width/2 - 18
        let pos = CGPoint(
            x: size.width/2 + cos(angle) * radius,
            y: size.height/2 + sin(angle) * radius
        )
        return PhaseIconLabel(
            icon: phaseIcons[idx % phaseIcons.count],
            label: phaseLabels[idx % phaseLabels.count],
            isActive: idx == currentPhase,
            position: pos
        )
    }
    func colorForPhase(idx: Int) -> Color {
        switch idx {
        case 0: return Color.orange
        case 1: return Color.blue
        case 2: return Color.green
        case 3: return Color.gray
        case 4: return Color.gray.opacity(0.5)
        default: return Color.gray
        }
    }
}

// MARK: - Micro-animations for Stat Modules
struct StatModuleView: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let theme: ColorTheme
    @State private var pulse = false
    @State private var bounce = false
    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme == .nike ? .green : color)
                .scaleEffect(icon == "heart.fill" && pulse ? 1.15 : 1.0)
                .animation(icon == "heart.fill" ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true) : .default, value: pulse)
                .onAppear { if icon == "heart.fill" { pulse = true } }
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(theme == .nike ? .green : color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .scaleEffect(label == "REP" && bounce ? 1.15 : 1.0)
                .animation(label == "REP" && bounce ? .interpolatingSpring(stiffness: 200, damping: 6) : .default, value: bounce)
                .onChange(of: value) { _, _ in if label == "REP" { bounce = true; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { bounce = false } } }
        }
        .frame(width: 50, height: 40)
        .background(theme == .nike ? Color.black : Color.black.opacity(0.18))
        .cornerRadius(8)
    }
}

// MARK: - Modular Stat Components (add theme param)
struct RestTimerModuleView: View {
    let restTime: String
    let progress: Double
    let theme: ColorTheme
    var body: some View {
        VStack(spacing: 2) {
            Text("Rest")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
            if progress > 0 && progress < 1.0 {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 6)
                Text(restTime)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
            } else {
                ProgressView(value: 0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                    .frame(height: 6)
                Text("--:--")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 80, height: 44)
        .background(Color.black.opacity(0.18))
        .cornerRadius(10)
    }
}

struct SplitTimeModuleView: View {
    let avg: String
    let last: String
    let theme: ColorTheme
    var body: some View {
        VStack(spacing: 2) {
            Text("Avg Split")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
            Text(avg)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(.primary)
            Text("Last: \(last)")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 44)
        .background(Color.black.opacity(0.18))
        .cornerRadius(10)
    }
}

// MARK: - Placeholder Modular Views
struct SprintGraphView: View {
    let viewModel: WorkoutWatchViewModel
    let theme: ColorTheme
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(theme == .nike ? Color.black : Color.gray.opacity(0.2))
            Text("Sprint Graph\n(Coming Soon)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 60)
    }
}

struct PaceModuleView: View {
    let pace: String
    let theme: ColorTheme
    var body: some View {
        VStack(spacing: 2) {
            Text("Pace")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
            Text(pace)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(theme == .nike ? .green : .primary)
        }
        .frame(width: 80, height: 44)
        .background(theme == .nike ? Color.black : Color.black.opacity(0.18))
        .cornerRadius(10)
    }
}

struct FatigueModuleView: View {
    let rpe: String
    let theme: ColorTheme
    var body: some View {
        VStack(spacing: 2) {
            Text("Fatigue")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
            Text(rpe)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(theme == .nike ? .green : .primary)
        }
        .frame(width: 80, height: 44)
        .background(theme == .nike ? Color.black : Color.black.opacity(0.18))
        .cornerRadius(10)
    }
}

struct LeaderboardModuleView: View {
    let rank: String
    let theme: ColorTheme
    var body: some View {
        VStack(spacing: 2) {
            Text("Rank")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.secondary)
            Text(rank)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(theme == .nike ? .green : .primary)
        }
        .frame(width: 80, height: 44)
        .background(theme == .nike ? Color.black : Color.black.opacity(0.18))
        .cornerRadius(10)
    }
}

// MARK: - BrandColorsWatch Accessibility Extension

#if DEBUG
#Preview("1. Main Workout - Apple Watch Ultra") {
    MainWorkoutWatchView(workoutVM: .mock)
        .preferredColorScheme(.dark)
}

#Preview("2. Workout Interface - Sprint Phase") {
    MainWorkoutWatchView(workoutVM: .mock)
        .preferredColorScheme(.dark)
}

#Preview("3. Stat Modules - Top Row") {
    HStack(spacing: WatchAdaptiveSizing.spacing) {
        StatModuleView(icon: "heart.fill", label: "BPM", value: "165", color: .green, theme: .apple)
        StatModuleView(icon: "ruler", label: "Yards", value: "40", color: .white, theme: .apple)
        StatModuleView(icon: "repeat", label: "Rep", value: "3/5", color: .accentColor, theme: .apple)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("4. Bottom Modules") {
    HStack(spacing: WatchAdaptiveSizing.spacing) {
        RestTimerModuleView(restTime: "2:30", progress: 0.6, theme: .apple)
        SplitTimeModuleView(avg: "4.85", last: "4.92", theme: .apple)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("5. Complete Watch Interface") {
    MainWorkoutWatchView(workoutVM: .mock)
        .preferredColorScheme(.dark)
}

#Preview("6. Adaptive Sizing - Ultra") {
    VStack(spacing: WatchAdaptiveSizing.spacing) {
        Text("Apple Watch Ultra Sizing")
            .font(.adaptiveTitle)
        Text("Adaptive spacing: \(Int(WatchAdaptiveSizing.spacing))px")
            .font(.adaptiveBody)
        Text("Module size: \(Int(WatchAdaptiveSizing.smallModuleSize.width))x\(Int(WatchAdaptiveSizing.smallModuleSize.height))")
            .font(.adaptiveCaption)
    }
    .adaptivePadding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
#endif

extension Color {
    /// Returns a color with improved contrast for accessibility (simple example, can be expanded)
    func accessible() -> Color {
        // Example: If color is too light, return black; if too dark, return white; else return self
        // In real app, use actual color contrast checking
        let uiColor = UIColor(self)
        var white: CGFloat = 0
        uiColor.getWhite(&white, alpha: nil)
        if white > 0.85 {
            return .black
        } else if white < 0.15 {
            return .white
        } else {
            return self
        }
    }
}

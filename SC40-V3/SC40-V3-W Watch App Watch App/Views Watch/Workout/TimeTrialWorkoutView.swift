import AVFoundation
import Combine
import CoreLocation
import SwiftUI
// import WatchKit  // Commented out - module not available in this scope

struct TimeTrialWorkoutView: View {
    @StateObject var workoutVM: WorkoutWatchViewModel
    @State private var showSummary = false
    @State private var showSprintView = false
    @State private var showRepLog = false
    @State private var selectedBottomModuleLeft: BottomModuleType = .rest
    @State private var selectedBottomModuleRight: BottomModuleType = .split
    @State private var showSprintGraph = false
    @State private var colorTheme: ColorTheme = .apple
    @State private var tabSelection = 1 // 0: Control, 1: Main, 2: Music
    @State private var animateScale = false
    @State private var showDistancePicker: Bool = false
    @State private var distance: Int = 40
    @State private var isSprintStarting = false
    private let speechSynth = AVSpeechSynthesizer()

    public init(workoutVM: WorkoutWatchViewModel) {
        _workoutVM = StateObject(wrappedValue: workoutVM)
    }
    
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
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            #if os(watchOS)
            WKInterfaceDevice.current().play(.click)
            #endif
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            #if os(watchOS)
            WKInterfaceDevice.current().play(.click)
            #endif
        }
        
        // Final start beep with haptic feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            #if os(watchOS)
            WKInterfaceDevice.current().play(.start)
            WKInterfaceDevice.current().play(.notification)
            #endif
        }
    }
    
    // MARK: - Top Row
    private var topStatsRow: some View {
        HStack(spacing: 6) {
            StatModuleView(icon: "heart.fill",
                           label: "BPM",
                           value: workoutVM.heartRateString,
                           color: .green,
                           theme: colorTheme)
            StatModuleView(icon: "ruler",
                           label: "Yards",
                           value: workoutVM.distanceRemainingString,
                           color: .white,
                           theme: colorTheme)
            StatModuleView(icon: "repeat",
                           label: "Rep",
                           value: "\(workoutVM.currentRep)/\(workoutVM.totalReps)",
                           color: .accentColor,
                           theme: colorTheme)
        }
    }
    
    // MARK: - Main Module
    private var mainModule: some View {
        VStack(spacing: 4) {
            if showSprintGraph {
                SprintGraphView(viewModel: workoutVM, theme: colorTheme)
                    .frame(height: 80)
            } else if workoutVM.isGPSPhase {
                GPSStopwatchView(viewModel: workoutVM, distance: distance)
                    .padding(.bottom, 4)
            } else {
                Text(workoutVM.stopwatchTimeString)
                    .font(.system(size: 42, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Text(workoutVM.currentPhaseLabel)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture()
                .onEnded { showSprintGraph.toggle() }
        )
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
                ControlWatchView(selectedIndex: 0, workoutVM: workoutVM)
                    .tag(0)
                mainTabContent
                    .tag(1)
                MusicWatchView(selectedIndex: 2)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .allowsHitTesting(tabSelection != 1) // Disable TabView gestures on main tab
        }
        .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { value in
                    // Only handle gestures when on main tab
                    guard tabSelection == 1 else { return }
                    print("🔍 TimeTrialView ZStack Drag in progress: x=\(value.translation.width), y=\(value.translation.height)")
                }
                .onEnded { value in
                    // Only handle gestures when on main tab
                    guard tabSelection == 1 else { return }
                    print("🔍 TimeTrialView ZStack Drag ended: x=\(value.translation.width), y=\(value.translation.height)")
                    
                    let horizontal = abs(value.translation.width) > abs(value.translation.height)
                    let threshold: CGFloat = 10
                    
                    if !horizontal {
                        // Vertical swipes (prioritize these)
                        if value.translation.height > threshold {
                            // Swipe down - RepLogWatchLiveView (available any time)
                            print("🔽 SWIPE DOWN DETECTED - showing RepLog")
                            withAnimation(.spring()) {
                                animateScale = true
                                // WKInterfaceDevice.current().play(.click)
                                showRepLog = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                animateScale = false
                            }
                        } else if value.translation.height < -threshold {
                            // Swipe up - SprintWatchView
                            print("🔼 SWIPE UP DETECTED - showing SprintView")
                            withAnimation(.spring()) {
                                animateScale = true
                                // WKInterfaceDevice.current().play(.directionUp)
                                showSprintView = true
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
                                tabSelection = 0
                            }
                        } else if value.translation.width < -20 {
                            // Swipe left - MusicWatchView  
                            print("⬅️ SWIPE LEFT DETECTED - switching to Music tab")
                            withAnimation(.spring()) {
                                tabSelection = 2
                            }
                        }
                    }
                }
        )
        .sheet(isPresented: $showDistancePicker) {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    Text("Distance")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top)
                    Spacer()
                    Picker("Distance", selection: $distance) {
                        ForEach([20, 30, 40, 50, 60, 100, 200], id: \.self) { value in
                            Text("\(value) yd").foregroundColor(.white)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .clipped()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    Spacer()
                    Button("Done") { showDistancePicker = false }
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(.bottom)
                }
            }
        }
        .onTapGesture {
            showDistancePicker = true
        }
        .onAppear { 
            workoutVM.setupUltra2Features() 
            print("📺 TimeTrialWorkoutView appeared - currentPhase: \(workoutVM.currentPhase)")
        }
        .onChange(of: showRepLog) { oldValue, newValue in
            print("🔄 TimeTrialView showRepLog changed: \(oldValue) → \(newValue)")
        }
        .fullScreenCover(isPresented: $showSummary) {
            RepLogSummaryFlowView(workoutVM: workoutVM, onDone: { showSummary = false })
        }
        .fullScreenCover(isPresented: $showSprintView) {
            SprintWatchView(viewModel: workoutVM, onDismiss: { showSprintView = false })
        }
        .fullScreenCover(isPresented: $showRepLog) {
            RepLogWatchLiveView(workoutVM: workoutVM,
                                horizontalTab: .constant(1),
                                isModal: true,
                                onDone: { showRepLog = false })
        }
    }
    
    // Main tab content with vertical drag gesture and animation
    private var mainTabContent: some View {
        VStack(spacing: 6) {
            topStatsRow
            Divider().background(Color.gray.opacity(0.4))
            mainModule
            Divider().background(Color.gray.opacity(0.4))
            bottomStatsRow
        }
        .padding(.horizontal, 6)
        .scaleEffect(animateScale ? 0.96 : 1.0)
        .animation(.easeOut(duration: 0.18), value: animateScale)
        .background(Color.clear)
        .contentShape(Rectangle())
        .gesture(
            // More aggressive direct gesture detection
            DragGesture(minimumDistance: 3, coordinateSpace: .local)
                .onEnded { value in
                    print("📱 TimeTrialView Direct content gesture: x=\(value.translation.width), y=\(value.translation.height)")
                    
                    // Prioritize vertical gestures with lower threshold
                    if abs(value.translation.height) > abs(value.translation.width) {
                        if value.translation.height > 8 {
                            print("🔽 DIRECT SWIPE DOWN - showing RepLog")
                            withAnimation(.spring()) {
                                animateScale = true
                                // WKInterfaceDevice.current().play(.click)
                                showRepLog = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                animateScale = false
                            }
                        } else if value.translation.height < -8 {
                            print("🔼 DIRECT SWIPE UP - showing SprintView")
                            withAnimation(.spring()) {
                                animateScale = true
                                // WKInterfaceDevice.current().play(.directionUp)
                                showSprintView = true
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

struct TimeTrialWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        TimeTrialWorkoutView(workoutVM: WorkoutWatchViewModel())
    }
}

struct GPSStopwatchView: View {
    @ObservedObject var viewModel: WorkoutWatchViewModel
    var distance: Int

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(min(viewModel.distanceTraveled / targetDistance, 1.0)))
                    .stroke(Color.blue, lineWidth: 8)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: viewModel.distanceTraveled)
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", viewModel.currentRepTime))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("sec")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(currentDistanceYards) yd")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .frame(width: 80, height: 80)
        }
    }

    private var targetDistance: Double {
        Double(currentDistanceYards) * 0.9144 // yards to meters
    }
    
    // Get the current rep's distance from the ViewModel
    private var currentDistanceYards: Int {
        let repIndex = viewModel.currentRep - 1
        if repIndex < viewModel.repDistances.count {
            return viewModel.repDistances[repIndex]
        }
        return distance // fallback to the passed distance parameter
    }
}

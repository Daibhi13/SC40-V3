import SwiftUI

// MARK: - Control Workout View - C25K Fitness22 Style
struct ControlWorkoutView: View {
    @Binding var isRunning: Bool
    @Binding var isPaused: Bool
    @Binding var currentPhase: MainProgramWorkoutView.WorkoutPhase
    @Binding var currentRep: Int
    @Binding var totalReps: Int
    @Binding var phaseTimeRemaining: Int
    
    let onPlayPause: () -> Void
    let onStop: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onVolumeToggle: () -> Void
    
    @State private var showVolumeIndicator = false
    @State private var volumeLevel: Double = 0.8
    
    var body: some View {
        ZStack {
            // Background matching the workout view
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.2, blue: 0.35),
                    Color(red: 0.2, green: 0.25, blue: 0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Timer Display Header
                timerHeaderView
                
                Spacer()
                
                // Control Buttons Grid
                controlButtonsGrid
                
                Spacer()
                
                // Page Indicator
                pageIndicatorView
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
        }
    }
    
    // MARK: - Timer Header
    private var timerHeaderView: some View {
        VStack(spacing: 8) {
            // Current time and total time
            HStack {
                Text(formatCurrentTime())
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("/")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(formatTotalTime())
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Current phase indicator
            Text(currentPhase.title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(currentPhase.color)
                .tracking(1)
        }
    }
    
    // MARK: - Control Buttons Grid
    private var controlButtonsGrid: some View {
        VStack(spacing: 20) {
            // Top row: Play/Pause and Stop
            HStack(spacing: 20) {
                // Play/Pause Button
                ControlButton(
                    icon: isRunning ? "pause.fill" : "play.fill",
                    color: .orange,
                    isActive: isRunning,
                    action: onPlayPause
                )
                
                // Stop Button
                ControlButton(
                    icon: "stop.fill",
                    color: .red,
                    isActive: false,
                    action: onStop
                )
            }
            
            // Bottom row: Previous and Next
            HStack(spacing: 20) {
                // Previous Button
                ControlButton(
                    icon: "backward.fill",
                    color: .blue,
                    isActive: false,
                    action: onPrevious
                )
                
                // Next Button
                ControlButton(
                    icon: "forward.fill",
                    color: .blue,
                    isActive: false,
                    action: onNext
                )
            }
            
            // Volume Control Button
            ControlButton(
                icon: "speaker.wave.2.fill",
                color: .gray,
                isActive: showVolumeIndicator,
                action: {
                    onVolumeToggle()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showVolumeIndicator.toggle()
                    }
                }
            )
            .scaleEffect(0.8) // Smaller size for volume button
        }
    }
    
    // MARK: - Page Indicator
    private var pageIndicatorView: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 8, height: 8)
            
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
            
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 8, height: 8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrentTime() -> String {
        let totalSessionTime = getTotalSessionTime()
        let elapsed = totalSessionTime - phaseTimeRemaining
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatTotalTime() -> String {
        let total = getTotalSessionTime()
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func getTotalSessionTime() -> Int {
        // Calculate total estimated session time
        return 30 * 60 // 30 minutes default
    }
}

// MARK: - Control Button Component
struct ControlButton: View {
    let icon: String
    let color: Color
    let isActive: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
            
            action()
        }) {
            ZStack {
                // Button background with gradient border
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 120, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(
                                LinearGradient(
                                    colors: isActive ? [color, color.opacity(0.6)] : [color.opacity(0.8), color.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(isActive ? color : color.opacity(0.8))
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isActive)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {}
    }
}

// MARK: - Pro Control Workout View for SprintTimerPro
struct ProControlWorkoutView: View {
    @Binding var isRunning: Bool
    @Binding var isPaused: Bool
    @Binding var currentPhase: SprintTimerProWorkoutView.WorkoutPhase
    @Binding var currentRep: Int
    @Binding var totalReps: Int
    @Binding var distance: Int
    @Binding var restMinutes: Int
    
    let onPlayPause: () -> Void
    let onStop: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onVolumeToggle: () -> Void
    
    var body: some View {
        ZStack {
            // Background matching the Pro workout view
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.2, blue: 0.35),
                    Color(red: 0.2, green: 0.25, blue: 0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Pro Timer Display Header
                proTimerHeaderView
                
                Spacer()
                
                // Control Buttons Grid (same as regular)
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        ControlButton(
                            icon: isRunning ? "pause.fill" : "play.fill",
                            color: .orange,
                            isActive: isRunning,
                            action: onPlayPause
                        )
                        
                        ControlButton(
                            icon: "stop.fill",
                            color: .red,
                            isActive: false,
                            action: onStop
                        )
                    }
                    
                    HStack(spacing: 20) {
                        ControlButton(
                            icon: "backward.fill",
                            color: .blue,
                            isActive: false,
                            action: onPrevious
                        )
                        
                        ControlButton(
                            icon: "forward.fill",
                            color: .blue,
                            isActive: false,
                            action: onNext
                        )
                    }
                    
                    ControlButton(
                        icon: "speaker.wave.2.fill",
                        color: .gray,
                        isActive: false,
                        action: onVolumeToggle
                    )
                    .scaleEffect(0.8)
                }
                
                Spacer()
                
                // Page Indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
        }
    }
    
    // MARK: - Pro Timer Header
    private var proTimerHeaderView: some View {
        VStack(spacing: 12) {
            // Rep counter
            HStack {
                Text("REP \(currentRep)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("OF \(totalReps)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Distance and rest info
            VStack(spacing: 4) {
                Text("\(distance) YARDS")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.yellow)
                
                Text("\(restMinutes) MIN REST")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Current phase
            Text("\(currentPhase)".uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(getPhaseColor())
                .tracking(1)
        }
    }
    
    private func getPhaseColor() -> Color {
        switch currentPhase {
        case .warmup: return .orange
        case .stretch: return .pink
        case .drill: return .indigo
        case .strides: return .purple
        case .sprints: return .green
        case .resting: return .yellow
        case .cooldown: return .blue
        case .completed: return .cyan
        }
    }
}

// MARK: - Swipeable Workout Container with Music and RepLog Support
struct SwipeableWorkoutContainer<MainContent: View, ControlContent: View, MusicContent: View, RepLogContent: View>: View {
    let mainContent: MainContent
    let controlContent: ControlContent
    let musicContent: MusicContent
    let repLogContent: RepLogContent
    
    @State private var dragOffset: CGPoint = .zero
    @State private var currentPage: Int = 1 // Start on main view (middle)
    @State private var showRepLog: Bool = false
    
    init(@ViewBuilder mainContent: () -> MainContent, 
         @ViewBuilder controlContent: () -> ControlContent,
         @ViewBuilder musicContent: () -> MusicContent,
         @ViewBuilder repLogContent: () -> RepLogContent) {
        self.mainContent = mainContent()
        self.controlContent = controlContent()
        self.musicContent = musicContent()
        self.repLogContent = repLogContent()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Horizontal swipe views
                HStack(spacing: 0) {
                    // Music view (left)
                    musicContent
                        .frame(width: geometry.size.width)
                    
                    // Main workout view (center)
                    mainContent
                        .frame(width: geometry.size.width)
                    
                    // Control view (right)
                    controlContent
                        .frame(width: geometry.size.width)
                }
                .offset(x: dragOffset.x - geometry.size.width) // Start centered on main view
                .opacity(showRepLog ? 0.3 : 1.0)
                .scaleEffect(showRepLog ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: showRepLog)
                
                // RepLog overlay (swipe up)
                if showRepLog {
                    repLogContent
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .background(Color.black.opacity(0.1))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let horizontalThreshold: CGFloat = 30
                        let verticalThreshold: CGFloat = 30
                        
                        if abs(value.translation.height) > abs(value.translation.width) && abs(value.translation.height) > verticalThreshold {
                            // Vertical swipe detected
                            if value.translation.height < -50 && !showRepLog {
                                // Swipe up to show RepLog
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showRepLog = true
                                }
                            } else if value.translation.height > 50 && showRepLog {
                                // Swipe down to hide RepLog
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showRepLog = false
                                }
                            }
                        } else if abs(value.translation.width) > horizontalThreshold && !showRepLog {
                            // Horizontal swipe for page navigation
                            dragOffset.x = value.translation.width - CGFloat(currentPage - 1) * geometry.size.width
                        }
                    }
                    .onEnded { value in
                        let horizontalThreshold: CGFloat = 50
                        let verticalThreshold: CGFloat = 100
                        
                        if abs(value.translation.height) > abs(value.translation.width) {
                            // Handle vertical swipe completion
                            if value.translation.height < -verticalThreshold && !showRepLog {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showRepLog = true
                                }
                            } else if value.translation.height > verticalThreshold && showRepLog {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showRepLog = false
                                }
                            }
                        } else if !showRepLog {
                            // Handle horizontal swipe completion
                            if value.translation.width < -horizontalThreshold {
                                // Swipe left
                                if currentPage < 2 {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        currentPage += 1
                                        dragOffset.x = CGFloat(currentPage - 1) * geometry.size.width
                                    }
                                } else {
                                    // Snap back if at rightmost page
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        dragOffset.x = CGFloat(currentPage - 1) * geometry.size.width
                                    }
                                }
                            } else if value.translation.width > horizontalThreshold {
                                // Swipe right
                                if currentPage > 0 {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        currentPage -= 1
                                        dragOffset.x = CGFloat(currentPage - 1) * geometry.size.width
                                    }
                                } else {
                                    // Snap back if at leftmost page
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        dragOffset.x = CGFloat(currentPage - 1) * geometry.size.width
                                    }
                                }
                            } else {
                                // Snap back to current page
                                withAnimation(.easeOut(duration: 0.3)) {
                                    dragOffset.x = CGFloat(currentPage - 1) * geometry.size.width
                                }
                            }
                        }
                    }
            )
        }
        .clipped()
    }
}

// MARK: - Legacy Two-View Container (for backward compatibility)
struct TwoViewSwipeableContainer<MainContent: View, ControlContent: View>: View {
    let mainContent: MainContent
    let controlContent: ControlContent
    
    @State private var dragOffset: CGFloat = 0
    @State private var currentPage: Int = 0
    
    init(@ViewBuilder mainContent: () -> MainContent, @ViewBuilder controlContent: () -> ControlContent) {
        self.mainContent = mainContent()
        self.controlContent = controlContent()
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main workout view
                mainContent
                    .frame(width: geometry.size.width)
                
                // Control view
                controlContent
                    .frame(width: geometry.size.width)
            }
            .offset(x: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width - CGFloat(currentPage) * geometry.size.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        
                        if value.translation.width < -threshold && currentPage == 0 {
                            // Swipe left to control view
                            withAnimation(.easeOut(duration: 0.3)) {
                                currentPage = 1
                                dragOffset = -geometry.size.width
                            }
                        } else if value.translation.width > threshold && currentPage == 1 {
                            // Swipe right back to main view
                            withAnimation(.easeOut(duration: 0.3)) {
                                currentPage = 0
                                dragOffset = 0
                            }
                        } else {
                            // Snap back to current page
                            withAnimation(.easeOut(duration: 0.3)) {
                                dragOffset = -CGFloat(currentPage) * geometry.size.width
                            }
                        }
                    }
            )
        }
        .clipped()
    }
}

#Preview("Control Workout View") {
    ControlWorkoutView(
        isRunning: .constant(true),
        isPaused: .constant(false),
        currentPhase: .constant(.sprints),
        currentRep: .constant(2),
        totalReps: .constant(4),
        phaseTimeRemaining: .constant(180),
        onPlayPause: {},
        onStop: {},
        onPrevious: {},
        onNext: {},
        onVolumeToggle: {}
    )
}

#Preview("Pro Control Workout View") {
    ProControlWorkoutView(
        isRunning: .constant(false),
        isPaused: .constant(true),
        currentPhase: .constant(.sprints),
        currentRep: .constant(1),
        totalReps: .constant(6),
        distance: .constant(40),
        restMinutes: .constant(3),
        onPlayPause: {},
        onStop: {},
        onPrevious: {},
        onNext: {},
        onVolumeToggle: {}
    )
}

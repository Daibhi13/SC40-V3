import SwiftUI
import AVFoundation

struct PremiumVoiceCoachSettingsView: View {
    @StateObject private var voiceCoach = PremiumVoiceCoach.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingUpgradePrompt = false
    @State private var showingVoicePreview = false
    @State private var previewMessage = "This is how your voice coach will sound during workouts."
    @State private var selectedPreviewMessage = 0
    
    var body: some View {
        NavigationView {
            Form {
                // Premium Status Section
                if !hasEliteAccess {
                    premiumUpgradeSection
                }
                
                // Voice Configuration Section
                voiceConfigurationSection
                
                // Coaching Style Section
                coachingStyleSection
                
                // Personality Section
                personalitySection
                
                // Advanced Settings Section
                if hasEliteAccess {
                    adaptiveCoachingSection
                }
                
                // Speech Control Section
                speechControlSection
                
                // Preview Section
                previewSection
                
                // Performance Insights Section
                if hasEliteAccess && voiceCoach.userPerformanceProfile != nil {
                    performanceInsightsSection
                }
            }
            .navigationTitle("Voice Coach Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .sheet(isPresented: $showingUpgradePrompt) {
            VoiceCoachUpgradeView()
        }
    }
    
    // MARK: - Premium Upgrade Section
    
    private var premiumUpgradeSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.yellow)
                
                Text("Unlock Premium Voice Coaching")
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Get AI-powered adaptive coaching, premium voices, and personalized feedback based on your performance.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    showingUpgradePrompt = true
                }) {
                    Text("Upgrade to Elite")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Voice Configuration Section
    
    private var voiceConfigurationSection: some View {
        Section("Voice Settings") {
            // Voice Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Voice Profile")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Voice", selection: $voiceCoach.selectedVoice) {
                    ForEach(voiceCoach.getAvailableVoices(), id: \.identifier) { voice in
                        HStack {
                            Text(voice.name)
                            if voice.isPremium {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                        .tag(voice)
                    }
                }
                .pickerStyle(.menu)
                .disabled(!hasProAccess)
            }
            
            // Voice Gender (Enhanced)
            HStack {
                Text("Voice Gender")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Picker("Gender", selection: $voiceCoach.selectedVoice) {
                    Text("Female").tag(PremiumVoiceCoach.VoiceProfile.defaultCoach)
                    if hasEliteAccess {
                        ForEach(PremiumVoiceCoach.VoiceProfile.premiumVoices, id: \.identifier) { voice in
                            Text(voice.gender).tag(voice)
                        }
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    // MARK: - Coaching Style Section
    
    private var coachingStyleSection: some View {
        Section {
            ForEach(voiceCoach.getAvailableCoachingStyles(), id: \.self) { style in
                CoachingStyleRow(
                    style: style,
                    isSelected: voiceCoach.coachingStyle == style,
                    hasAccess: !style.isPremium || hasEliteAccess
                ) {
                    if style.isPremium && !hasEliteAccess {
                        showingUpgradePrompt = true
                    } else {
                        voiceCoach.updateCoachingStyle(style)
                    }
                }
            }
        } footer: {
            Text("Choose the coaching style that motivates you best during workouts.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Personality Section
    
    private var personalitySection: some View {
        Section {
            ForEach(PremiumVoiceCoach.VoicePersonality.allCases, id: \.self) { personality in
                PersonalityRow(
                    personality: personality,
                    isSelected: voiceCoach.voicePersonality == personality,
                    hasAccess: !personality.isPremium || hasEliteAccess
                ) {
                    if personality.isPremium && !hasEliteAccess {
                        showingUpgradePrompt = true
                    } else {
                        voiceCoach.updateVoicePersonality(personality)
                    }
                }
            }
        } footer: {
            Text("Select the personality type that resonates with your training mindset.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Adaptive Coaching Section
    
    private var adaptiveCoachingSection: some View {
        Section {
            // Adaptive Level
            VStack(alignment: .leading, spacing: 8) {
                Text("Intelligence Level")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Intelligence Level", selection: $voiceCoach.adaptiveLevel) {
                    ForEach(PremiumVoiceCoach.AdaptiveLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Natural Speech Features
            Toggle("Natural Speech Pauses", isOn: $voiceCoach.useNaturalPauses)
            Toggle("Contextual Awareness", isOn: $voiceCoach.contextualAwareness)
            
            // Performance Adaptation
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Performance Adaptation")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(voiceCoach.adaptiveLevel == .aiPowered ? "Active" : "Basic")
                        .font(.caption)
                        .foregroundColor(voiceCoach.adaptiveLevel == .aiPowered ? .green : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(voiceCoach.adaptiveLevel == .aiPowered ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        )
                }
                
                Text("AI analyzes your performance patterns and adapts coaching style in real-time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } footer: {
            Text("AI-powered features adapt coaching based on your performance history and current workout context.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Speech Control Section
    
    private var speechControlSection: some View {
        Section("Speech Control") {
            // Speech Rate
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Speech Rate")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(speechRateDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $voiceCoach.speechRate,
                    in: 0.3...0.8,
                    step: 0.1
                ) {
                    Text("Speech Rate")
                } minimumValueLabel: {
                    Text("Slow")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("Fast")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Volume
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Volume")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(voiceCoach.volume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $voiceCoach.volume,
                    in: 0.1...1.0,
                    step: 0.1
                ) {
                    Text("Volume")
                } minimumValueLabel: {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Voice Coaching Toggle
            Toggle("Enable Voice Coaching", isOn: $voiceCoach.isEnabled)
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        Section("Preview") {
            Button(action: {
                previewVoiceCoach()
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Preview Voice Coach")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Hear how your settings sound")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if voiceCoach.isSpeaking {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .foregroundColor(.primary)
            }
            .disabled(voiceCoach.isSpeaking)
            
            // Sample Messages Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Sample Messages")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Sample Message", selection: $selectedPreviewMessage) {
                    ForEach(Array(sampleMessages.enumerated()), id: \.offset) { index, message in
                        Text(message.prefix(30) + "...").tag(index)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedPreviewMessage) { newValue in
                    previewMessage = sampleMessages[newValue]
                }
            }
        }
    }
    
    // MARK: - Performance Insights Section
    
    private var performanceInsightsSection: some View {
        Section("Performance Insights") {
            if let profile = voiceCoach.userPerformanceProfile {
                VStack(alignment: .leading, spacing: 12) {
                    // Experience Level
                    HStack {
                        Text("Experience Level")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(profile.experience.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    // Consistency Score
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Consistency Score")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(Int(profile.consistencyScore * 100))%")
                                .font(.subheadline)
                                .foregroundColor(consistencyColor(profile.consistencyScore))
                        }
                        
                        ProgressView(value: profile.consistencyScore)
                            .progressViewStyle(LinearProgressViewStyle(tint: consistencyColor(profile.consistencyScore)))
                    }
                    
                    // Strengths
                    if !profile.strengths.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Strengths")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(profile.strengths, id: \.self) { strength in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text(strength.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Improvement Areas
                    if !profile.improvementAreas.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Focus Areas")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(profile.improvementAreas, id: \.self) { area in
                                HStack {
                                    Image(systemName: "target")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    
                                    Text(area.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Complete a few workouts to see personalized insights")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var hasProAccess: Bool {
        subscriptionManager.hasAccess(to: .autonomousWorkouts)
    }
    
    private var hasEliteAccess: Bool {
        subscriptionManager.hasAccess(to: .biomechanicsAnalysis)
    }
    
    private var speechRateDescription: String {
        switch voiceCoach.speechRate {
        case 0.3...0.4: return "Very Slow"
        case 0.4...0.5: return "Slow"
        case 0.5...0.6: return "Normal"
        case 0.6...0.7: return "Fast"
        default: return "Very Fast"
        }
    }
    
    private var sampleMessages: [String] {
        [
            "Welcome back! Ready to crush today's sprint session?",
            "Excellent acceleration! Keep building that speed!",
            "Strong finish! You're in PR territory!",
            "Focus on your form. Relaxed but powerful.",
            "Outstanding consistency across all reps today!",
            "Three... two... one... GO!",
            "That's championship-level execution right there!",
            "Your technique is looking sharp today. Trust it."
        ]
    }
    
    // MARK: - Helper Methods
    
    private func previewVoiceCoach() {
        voiceCoach.speak(
            previewMessage,
            priority: .medium,
            context: .motivation
        )
    }
    
    private func consistencyColor(_ score: Double) -> Color {
        if score > 0.8 { return .green }
        else if score > 0.6 { return .orange }
        else { return .red }
    }
}

// MARK: - Supporting Views

struct CoachingStyleRow: View {
    let style: PremiumVoiceCoach.CoachingStyle
    let isSelected: Bool
    let hasAccess: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(style.rawValue)
                            .fontWeight(isSelected ? .semibold : .regular)
                        
                        if style.isPremium {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    Text(style.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .foregroundColor(.primary)
            .opacity(hasAccess ? 1.0 : 0.6)
        }
        .disabled(!hasAccess)
    }
}

struct PersonalityRow: View {
    let personality: PremiumVoiceCoach.VoicePersonality
    let isSelected: Bool
    let hasAccess: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(personality.rawValue)
                            .fontWeight(isSelected ? .semibold : .regular)
                        
                        if personality.isPremium {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    Text(personalityDescription(personality))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .foregroundColor(.primary)
            .opacity(hasAccess ? 1.0 : 0.6)
        }
        .disabled(!hasAccess)
    }
    
    private func personalityDescription(_ personality: PremiumVoiceCoach.VoicePersonality) -> String {
        switch personality {
        case .professional: return "Confident and clear coaching"
        case .mentor: return "Warm and wise guidance"
        case .teammate: return "Friendly training partner"
        case .champion: return "Powerful champion mindset"
        case .scientist: return "Analytical performance focus"
        }
    }
}

struct VoiceCoachUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.yellow)
                    
                    Text("Unlock Premium Voice Coaching")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Get AI-powered adaptive coaching that learns from your performance and provides personalized feedback.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Features List
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "brain.head.profile", title: "AI-Powered Adaptation", description: "Coaching adapts to your performance patterns")
                    FeatureRow(icon: "waveform.and.mic", title: "Premium Voices", description: "Professional athlete and elite coach voices")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Performance Insights", description: "Personalized coaching based on your data")
                    FeatureRow(icon: "speaker.wave.3", title: "Natural Speech", description: "Human-like pauses and contextual awareness")
                }
                
                Spacer()
                
                // Upgrade Buttons
                VStack(spacing: 12) {
                    Button("Upgrade to Elite - $29.99/month") {
                        // Handle Elite upgrade
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    
                    Button("Start with Pro - $9.99/month") {
                        // Handle Pro upgrade
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                    
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    PremiumVoiceCoachSettingsView()
}

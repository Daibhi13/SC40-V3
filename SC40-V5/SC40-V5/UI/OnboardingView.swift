//
//  OnboardingView.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import SwiftUI

/// User setup flow for first-time users
struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var fitnessLevel: UserProfile.FitnessLevel = .beginner
    @State private var preferredUnits: UserProfile.UnitSystem = .metric
    @State private var notificationsEnabled = true

    private let steps = ["Welcome", "Profile", "Preferences", "Complete"]

    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)

            VStack {
                // Progress indicator
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .padding(.horizontal)
                    .padding(.top, 50)

                Spacer()

                // Current step content
                switch currentStep {
                case 0:
                    WelcomeStep()
                case 1:
                    ProfileStep(userName: $userName, userEmail: $userEmail)
                case 2:
                    PreferencesStep(fitnessLevel: $fitnessLevel,
                                  preferredUnits: $preferredUnits,
                                  notificationsEnabled: $notificationsEnabled)
                case 3:
                    CompleteStep()
                default:
                    WelcomeStep()
                }

                Spacer()

                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            currentStep -= 1
                        }
                        .foregroundColor(.white)
                        .padding()
                    }

                    Spacer()

                    Button(currentStep == steps.count - 1 ? "Get Started" : "Next") {
                        if currentStep == steps.count - 1 {
                            completeOnboarding()
                        } else {
                            currentStep += 1
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
        }
    }

    private func completeOnboarding() {
        // Save user profile and preferences
        print("Onboarding completed with: \(userName), \(fitnessLevel.rawValue)")
        // Dismiss the onboarding view
    }
}

// MARK: - Onboarding Steps

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "figure.run")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.white)

            Text("Welcome to SC40-V5")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("Your AI-powered sprint training companion")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Text("Let's set up your profile to create personalized training sessions")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

struct ProfileStep: View {
    @Binding var userName: String
    @Binding var userEmail: String

    var body: some View {
        VStack(spacing: 30) {
            Text("Tell us about yourself")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            VStack(spacing: 20) {
                TextField("Full Name", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Email Address", text: $userEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal)
            }
        }
    }
}

struct PreferencesStep: View {
    @Binding var fitnessLevel: UserProfile.FitnessLevel
    @Binding var preferredUnits: UserProfile.UnitSystem
    @Binding var notificationsEnabled: Bool

    var body: some View {
        VStack(spacing: 30) {
            Text("Training Preferences")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            VStack(spacing: 20) {
                Picker("Fitness Level", selection: $fitnessLevel) {
                    ForEach(UserProfile.FitnessLevel.allCases, id: \.self) { level in
                        Text(level.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                Picker("Units", selection: $preferredUnits) {
                    ForEach(UserProfile.UnitSystem.allCases, id: \.self) { unit in
                        Text(unit.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .foregroundColor(.white)
                    .padding(.horizontal)
            }
        }
    }
}

struct CompleteStep: View {
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)

            Text("All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("Your profile is ready. Let's start your sprint training journey!")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

//
//  ContentView.swift
//  SC40-V3
//
//  Created by David O'Connell on 05/11/2025.
//

import SwiftUI

// CLEAN ContentView - Direct to onboarding for testing
struct ContentView: View {
    @StateObject private var userProfileVM = UserProfileViewModel()
    @StateObject private var syncManager = TrainingSynchronizationManager.shared
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    
    var body: some View {
        Group {
            if !onboardingCompleted {
                // Skip WelcomeView - go straight to onboarding for testing
                OnboardingView(
                    userName: "User",
                    userProfileVM: userProfileVM,
                    onComplete: {
                        onboardingCompleted = true
                    }
                )
            } else {
                TrainingView(userProfileVM: userProfileVM)
                    .environmentObject(syncManager)
            }
        }
    }
}

#Preview {
    ContentView()
}

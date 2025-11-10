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
    @State private var showTrainingView = false
    
    var body: some View {
        Group {
            if !onboardingCompleted {
                // Skip WelcomeView - go straight to onboarding for testing
                OnboardingView(
                    userName: "User",
                    userProfileVM: userProfileVM,
                    onComplete: {
                        // CRASH FIX: Delay TrainingView presentation to prevent AudioGraph crashes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onboardingCompleted = true
                            showTrainingView = true
                        }
                    }
                )
            } else if showTrainingView || onboardingCompleted {
                TrainingView(userProfileVM: userProfileVM)
                    .environmentObject(syncManager)
                    .onAppear {
                        showTrainingView = true
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}

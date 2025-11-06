//
//  ContentView.swift
//  SC40-V3
//
//  Created by David O'Connell on 05/11/2025.
//

import SwiftUI

// CLEAN ContentView - Direct to onboarding for testing
struct ContentView: View {
    @StateObject private var userProfileVM: UserProfileViewModel = {
        print("📱 ContentView: Creating UserProfileViewModel...")
        let vm = UserProfileViewModel()
        print("✅ ContentView: UserProfileViewModel created")
        return vm
    }()
    
    @StateObject private var syncManager: TrainingSynchronizationManager = {
        print("📱 ContentView: Getting TrainingSynchronizationManager.shared...")
        let manager = TrainingSynchronizationManager.shared
        print("✅ ContentView: TrainingSynchronizationManager.shared obtained")
        return manager
    }()
    
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    
    init() {
        print("🎬 ContentView: INIT CALLED")
    }
    
    var body: some View {
        let _ = print("📱 ContentView: body EVALUATING")
        let _ = print("   onboardingCompleted: \(onboardingCompleted)")
        return Group {
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

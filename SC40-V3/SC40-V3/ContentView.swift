//
//  ContentView.swift
//  SC40-V3
//
//  Created by David O'Connell on 05/11/2025.
//

import SwiftUI

// CLEAN ContentView - Simple navigation without corruption
struct ContentView: View {
    @StateObject private var userProfileVM = UserProfileViewModel()
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    @State private var showWelcome = true
    @State private var userName = ""
    
    var body: some View {
        Group {
            if !onboardingCompleted {
                if showWelcome {
                    WelcomeView(onContinue: { name, _ in
                        userName = name
                        showWelcome = false
                    })
                } else {
                    OnboardingView(
                        userName: userName,
                        userProfileVM: userProfileVM,
                        onComplete: {
                            onboardingCompleted = true
                        }
                    )
                }
            } else {
                TrainingView(userProfileVM: userProfileVM)
            }
        }
    }
}

#Preview {
    ContentView()
}

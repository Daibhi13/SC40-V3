//
//  ContentView.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import SwiftUI
import Combine

/// Main app flow coordinator and navigation hub
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var selectedTab = 0
    @State private var showSideMenu = false
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            // Main content based on selected tab
            switch selectedTab {
            case 0:
                HomeView()
                    .transition(.slide)
            case 1:
                TrainingView()
                    .transition(.slide)
            case 2:
                ProgressView()
                    .transition(.slide)
            case 3:
                SocialView()
                    .transition(.slide)
            default:
                HomeView()
                    .transition(.slide)
            }

            // Side menu overlay
            if showSideMenu {
                SideMenuView(isVisible: $showSideMenu, selectedTab: $selectedTab)
                    .transition(.move(edge: .leading))
            }
        }
        .overlay(alignment: .topLeading) {
            // Hamburger menu button
            Button {
                withAnimation {
                    showSideMenu.toggle()
                }
            } label: {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(16)
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
            }
            .padding(.leading, 20)
            .padding(.top, 50)
            .zIndex(2)
        }
        .overlay(alignment: .topTrailing) {
            // Profile button
            Button {
                // Navigate to profile
            } label: {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(16)
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
            }
            .padding(.trailing, 20)
            .padding(.top, 50)
            .zIndex(2)
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing)
        )
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onAppear {
            checkFirstLaunch()
        }
    }

    private func checkFirstLaunch() {
        if viewModel.isFirstLaunch {
            showOnboarding = true
        }
    }
}

// MARK: - Tab Views

struct HomeView: View {
    var body: some View {
        VStack {
            Text("SC40-V5 Sprint Coach")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()

            Text("Welcome to your sprint training journey!")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Quick action buttons
            VStack(spacing: 20) {
                NavigationLink(destination: TrainingView()) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                        Text("Start Training")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }

                Button {
                    // Quick workout
                } label: {
                    HStack {
                        Image(systemName: "bolt.circle.fill")
                            .font(.title2)
                        Text("Quick Session")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}

struct ProgressView: View {
    var body: some View {
        VStack {
            Text("Progress Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()
        }
    }
}

struct SocialView: View {
    var body: some View {
        VStack {
            Text("Social Hub")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()
        }
    }
}

// MARK: - View Model

class ContentViewModel: ObservableObject {
    @Published var isFirstLaunch: Bool = true
    @Published var userProfile: UserProfile?
    @Published var currentSession: TrainingSession?

    init() {
        checkUserProfile()
    }

    private func checkUserProfile() {
        // Check if user profile exists in UserDefaults or Core Data
        // For now, assume first launch if no profile exists
        isFirstLaunch = true // This would be determined by actual data check
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

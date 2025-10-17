//
//  SideMenuView.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import SwiftUI
import Combine

/// Navigation side menu for the app
struct SideMenuView: View {
    @Binding var isVisible: Bool
    @Binding var selectedTab: Int

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isVisible = false
                    }
                }

            // Menu content
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    SideMenuHeader()

                    // Menu items
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(MenuItem.allCases, id: \.self) { item in
                                SideMenuItemView(item: item,
                                               isSelected: selectedTab == item.tabIndex,
                                               selectedTab: $selectedTab,
                                               isVisible: $isVisible)
                            }
                        }
                    }

                    Spacer()

                    // Bottom section
                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                            .background(Color.white.opacity(0.3))

                        ForEach(BottomMenuItem.allCases, id: \.self) { item in
                            SideMenuItemView(item: item,
                                           isSelected: false,
                                           selectedTab: $selectedTab,
                                           isVisible: $isVisible)
                        }
                    }
                }
                .frame(width: 280)
                .background(Color.black.opacity(0.9))
                .edgesIgnoringSafeArea(.vertical)

                Spacer()
            }
        }
        .zIndex(1)
    }
}

// MARK: - Header

struct SideMenuHeader: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.white)

                VStack(alignment: .leading) {
                    Text("SC40-V5 User")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Premium Member")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }

                Spacer()
            }
            .padding()

            Divider()
                .background(Color.white.opacity(0.3))
        }
    }
}

// MARK: - Menu Item View

struct SideMenuItemView: View {
    let item: MenuItemProtocol
    let isSelected: Bool
    @Binding var selectedTab: Int
    @Binding var isVisible: Bool

    var body: some View {
        Button(action: {
            if item.tabIndex >= 0 {
                selectedTab = item.tabIndex
            } else {
                // Handle special actions
                handleMenuAction(item)
            }

            withAnimation {
                isVisible = false
            }
        }) {
            HStack {
                Image(systemName: item.iconName)
                    .font(.title2)
                    .frame(width: 30)
                    .foregroundColor(isSelected ? .blue : .white)

                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if item.hasNotification {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }
            .padding()
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func handleMenuAction(_ item: MenuItemProtocol) {
        switch item {
        case let bottomItem as BottomMenuItem:
            switch bottomItem {
            case .settings:
                // Navigate to settings
                print("Navigate to settings")
            case .help:
                // Show help
                print("Show help")
            case .about:
                // Show about
                print("Show about")
            case .logout:
                // Handle logout
                print("Logout")
            }
        default:
            break
        }
    }
}

// MARK: - Menu Items

enum MenuItem: Int, CaseIterable, MenuItemProtocol {
    case home = 0
    case training = 1
    case progress = 2
    case social = 3
    case challenges = 4
    case leaderboard = 5
    case schedule = 6

    var title: String {
        switch self {
        case .home: return "Home"
        case .training: return "Training"
        case .progress: return "Progress"
        case .social: return "Social"
        case .challenges: return "Challenges"
        case .leaderboard: return "Leaderboard"
        case .schedule: return "Schedule"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .training: return "figure.run"
        case .progress: return "chart.bar.fill"
        case .social: return "person.3.fill"
        case .challenges: return "trophy.fill"
        case .leaderboard: return "list.number"
        case .schedule: return "calendar"
        }
    }

    var tabIndex: Int { return rawValue }
    var hasNotification: Bool { return false }
}

enum BottomMenuItem: Int, CaseIterable, MenuItemProtocol {
    case settings = -1
    case help = -2
    case about = -3
    case logout = -4

    var title: String {
        switch self {
        case .settings: return "Settings"
        case .help: return "Help & Support"
        case .about: return "About"
        case .logout: return "Logout"
        }
    }

    var iconName: String {
        switch self {
        case .settings: return "gear"
        case .help: return "questionmark.circle"
        case .about: return "info.circle"
        case .logout: return "arrow.right.square"
        }
    }

    var tabIndex: Int { return rawValue }
    var hasNotification: Bool { return false }
}

// MARK: - Protocol

protocol MenuItemProtocol {
    var title: String { get }
    var iconName: String { get }
    var tabIndex: Int { get }
    var hasNotification: Bool { get }
}

// MARK: - View Model

class SideMenuViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var isVisible: Bool = false

    func selectTab(_ tab: Int) {
        selectedTab = tab
    }
}

// MARK: - Preview

struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView(isVisible: .constant(true), selectedTab: .constant(0))
    }
}

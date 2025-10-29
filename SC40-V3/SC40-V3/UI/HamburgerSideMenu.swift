import SwiftUI

// MARK: - Menu Selection Types
enum MenuSelection {
    case main
    case history
    case leaderboard
    case smartHub
    case watchConnectivity
    case settings
    case helpInfo
    case news
    case shareWithTeammates
    case sharePerformance
    case proFeatures
    case performanceTrends
    case advancedAnalytics
}

// MARK: - Menu Row Component
struct HamburgerMenuRow: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    let showProBadge: Bool

    init(icon: String, label: String, color: Color, action: @escaping () -> Void, showProBadge: Bool = false) {
        self.icon = icon
        self.label = label
        self.color = color
        self.action = action
        self.showProBadge = showProBadge
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .medium))

                Text(label)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)

                if showProBadge {
                    ProBadge()
                }

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Pro Badge Component
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 1.0, green: 0.8, blue: 0.0))
            )
    }
}

// MARK: - Hamburger Side Menu
struct HamburgerSideMenu<MenuType>: View {
    @Binding var showMenu: Bool
    var onSelect: (MenuType) -> Void
    
    // Stable state management to prevent flickering
    @State private var isVisible: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Premium semi-transparent overlay with stable positioning
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        dismissMenu()
                    }

                // Side menu panel with fixed constraints
                VStack(alignment: .leading, spacing: 0) {
                    // Top spacing for status bar - add extra padding
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: max(geometry.safeAreaInsets.top + 20, 60))

                // Menu items with proper spacing
                VStack(spacing: 4) {
                    HamburgerMenuRow(icon: "figure.run", label: "Sprint 40 yards", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        selectMenuItem(MenuSelection.main as! MenuType)
                    })

                    HamburgerMenuRow(icon: "clock.arrow.circlepath", label: "History", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        selectMenuItem(MenuSelection.history as! MenuType)
                    })

                    HamburgerMenuRow(icon: "chart.bar.xaxis", label: "Leaderboard", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        selectMenuItem(MenuSelection.leaderboard as! MenuType)
                    })

                    HamburgerMenuRow(icon: "chart.line.uptrend.xyaxis", label: "Advanced Analytics", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        selectMenuItem(MenuSelection.advancedAnalytics as! MenuType)
                    }, showProBadge: true)

                    HamburgerMenuRow(icon: "square.and.arrow.up", label: "Share Performance", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        selectMenuItem(MenuSelection.sharePerformance as! MenuType)
                    })

                    HamburgerMenuRow(icon: "lightbulb", label: "40 Yard Smart", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        selectMenuItem(MenuSelection.smartHub as! MenuType)
                    })

                    HamburgerMenuRow(icon: "applewatch", label: "Watch Connectivity", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        selectMenuItem(MenuSelection.watchConnectivity as! MenuType)
                    })

                    HamburgerMenuRow(icon: "gearshape", label: "Settings", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        selectMenuItem(MenuSelection.settings as! MenuType)
                    })

                    HamburgerMenuRow(icon: "questionmark.circle", label: "Help & info", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        selectMenuItem(MenuSelection.helpInfo as! MenuType)
                    })

                    HamburgerMenuRow(icon: "newspaper", label: "News", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        selectMenuItem(MenuSelection.news as! MenuType)
                    })
                }

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

                // Pro features section (if applicable)
                if let _ = MenuType.self as? MenuSelection.Type {
                    HamburgerMenuRow(icon: "person.3.fill", label: "Share with Team Mates", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        selectMenuItem(MenuSelection.shareWithTeammates as! MenuType)
                    })

                    Spacer(minLength: 16)

                    HStack {
                        Spacer()
                        HamburgerMenuRow(icon: "lock.shield", label: "Pro Features", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                            selectMenuItem(MenuSelection.proFeatures as! MenuType)
                        }, showProBadge: true)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                Spacer(minLength: 20)

                // Bottom section with Accelerate and social icons
                VStack(spacing: 16) {
                    HStack {
                        HamburgerMenuRow(icon: "figure.run", label: "Accelerate", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                            // Navigate to main training view
                            selectMenuItem(MenuSelection.main as! MenuType)
                        })
                    }
                    .padding(.horizontal, 24)

                    HStack(spacing: 24) {
                        Button(action: { 
                            // Open Facebook page
                            if let url = URL(string: "https://www.facebook.com/SprintCoach40") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Image(systemName: "f.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 1.0))
                        }
                        
                        Button(action: { 
                            // Open Instagram page
                            if let url = URL(string: "https://www.instagram.com/sprintcoach40") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.8))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                }
            }
            .frame(width: 280, height: geometry.size.height)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),  // Dark blue top
                        Color(red: 0.2, green: 0.1, blue: 0.3),  // Purple middle
                        Color(red: 0.1, green: 0.05, blue: 0.2)  // Dark purple bottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            )
            .shadow(color: .black.opacity(0.5), radius: 20, x: 5, y: 0)
            .offset(x: isVisible ? 0 : -280)
            .animation(.easeInOut(duration: 0.3), value: isVisible)
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
        }
    }
    
    // MARK: - Helper Methods
    private func dismissMenu() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showMenu = false
            }
        }
    }
    
    private func selectMenuItem(_ selection: MenuType) {
        // Add haptic feedback for menu selection
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        onSelect(selection)
        dismissMenu()
    }
}

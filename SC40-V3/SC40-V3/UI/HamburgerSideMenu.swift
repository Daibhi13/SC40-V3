import SwiftUI

// MARK: - Menu Selection Types
enum HamburgerMenuSelection {
    case main
    case history
    case leaderboard
    case smartHub
    case settings
    case helpInfo
    case news
    case shareWithTeammates
    case sharePerformance
    case proFeatures
    case performanceTrends
}

// MARK: - Menu Row Component
struct HamburgerMenuRow: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

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

                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Hamburger Side Menu
struct HamburgerSideMenu<MenuType>: View {
    @Binding var showMenu: Bool
    var onSelect: (MenuType) -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Premium semi-transparent overlay
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showMenu = false
                    }
                }

            // Side menu panel
            VStack(alignment: .leading, spacing: 0) {
                // Top spacing for status bar
                Spacer().frame(height: 60)

                // Menu items
                VStack(spacing: 0) {
                    HamburgerMenuRow(icon: "bolt.fill", label: "Sprint 40 yards", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        onSelect(HamburgerMenuSelection.main as! MenuType)
                        withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                    })

                    HamburgerMenuRow(icon: "clock.arrow.circlepath", label: "History", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        onSelect(HamburgerMenuSelection.history as! MenuType)
                        withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                    })

                    HamburgerMenuRow(icon: "chart.bar.xaxis", label: "Leaderboard", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        onSelect(HamburgerMenuSelection.leaderboard as! MenuType)
                        withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                    })

                    HamburgerMenuRow(icon: "square.and.arrow.up", label: "Share Performance", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        onSelect(HamburgerMenuSelection.sharePerformance as! MenuType)
                        withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                    })

                    HamburgerMenuRow(icon: "lightbulb", label: "40 Yard Smart", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        onSelect(HamburgerMenuSelection.smartHub as! MenuType)
                        withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                    })

                    HamburgerMenuRow(icon: "gearshape", label: "Settings", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        onSelect(HamburgerMenuSelection.settings as! MenuType)
                        withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                    })

                    HamburgerMenuRow(icon: "questionmark.circle", label: "Help & info", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        onSelect(HamburgerMenuSelection.helpInfo as! MenuType)
                        withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                    })

                    HamburgerMenuRow(icon: "newspaper", label: "News", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        onSelect(HamburgerMenuSelection.news as! MenuType)
                        withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                    })
                }

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 20)

                // Pro features section (if applicable)
                if let _ = MenuType.self as? HamburgerMenuSelection.Type {
                    HamburgerMenuRow(icon: "person.3.fill", label: "Share with Team Mates", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                        onSelect(HamburgerMenuSelection.shareWithTeammates as! MenuType)
                        withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                    })

                    Spacer(minLength: 24)

                    HStack {
                        Spacer()
                        HamburgerMenuRow(icon: "lock.shield", label: "Pro Features", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                            onSelect(HamburgerMenuSelection.proFeatures as! MenuType)
                            withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                        })
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Spacer()

                // Bottom section with Accelerate and social icons
                VStack(spacing: 16) {
                    HStack {
                        HamburgerMenuRow(icon: "hare.fill", label: "Accelerate", color: Color(red: 1.0, green: 0.8, blue: 0.0), action: {
                            // Accelerate action
                            withAnimation(.easeInOut(duration: 0.3)) { showMenu = false }
                        })
                    }
                    .padding(.horizontal, 24)

                    HStack(spacing: 24) {
                        Image(systemName: "f.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 1.0))
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 0.8, green: 0.3, blue: 0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 32)
                }
            }
            .frame(width: 280)
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
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            )
            .shadow(color: .black.opacity(0.5), radius: 20, x: 5, y: 0)
            .edgesIgnoringSafeArea(.vertical)
        }
        .transition(.move(edge: .leading))
    }
}

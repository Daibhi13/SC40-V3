import SwiftUI
import Combine

struct SideMenuView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var profileManager: ProfileManager
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Menu content
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading) {
                        Text("Sprint Coach 40")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let profile = profileManager.currentProfile {
                            Text("Welcome, \(profile.name)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue)
                    
                    // Menu items
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            MenuItem(icon: "house.fill", title: "Home", action: {
                                isPresented = false
                            })
                            
                            MenuItem(icon: "figure.run", title: "Training Plans", action: {
                                isPresented = false
                            })
                            
                            MenuItem(icon: "chart.bar.fill", title: "Progress", action: {
                                isPresented = false
                            })
                            
                            MenuItem(icon: "person.3.fill", title: "Social", action: {
                                isPresented = false
                            })
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                                .padding(.vertical, 8)
                            
                            MenuItem(icon: "person.circle", title: "Profile", action: {
                                isPresented = false
                            })
                            
                            MenuItem(icon: "gear", title: "Settings", action: {
                                isPresented = false
                            })
                            
                            MenuItem(icon: "questionmark.circle", title: "Help & Support", action: {
                                isPresented = false
                            })
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                                .padding(.vertical, 8)
                            
                            MenuItem(icon: "arrow.right.square", title: "Sign Out", action: {
                                isPresented = false
                                // Handle sign out
                            })
                        }
                    }
                    
                    Spacer()
                }
                .frame(width: 280)
                .background(Color(UIColor.systemBackground))
                .edgesIgnoringSafeArea(.bottom)
                
                Spacer()
            }
        }
    }
}

struct MenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 24)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    SideMenuView(isPresented: .constant(true))
        .environmentObject(ProfileManager())
}

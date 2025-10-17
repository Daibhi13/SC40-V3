import SwiftUI

struct SideMenuView: View {
    @State private var showSettings = false
    @State private var showSharePerformance = false
    @ObservedObject var userProfileVM: UserProfileViewModel
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: UserProfileView(userProfileVM: userProfileVM)) {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                
                Button(action: { showSharePerformance = true }) {
                    Label("Share Performance", systemImage: "square.and.arrow.up")
                }
                
                Button(action: { showSettings = true }) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("Menu")
            .sheet(isPresented: $showSettings) {
                SettingsView(userProfileVM: userProfileVM)
            }
            .sheet(isPresented: $showSharePerformance) {
                SharePerformanceView()
            }
        }
    }
}

#Preview {
    SideMenuView(userProfileVM: UserProfileViewModel())
}

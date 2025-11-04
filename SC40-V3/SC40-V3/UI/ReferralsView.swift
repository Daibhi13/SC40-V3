import SwiftUI

struct ReferralsView: View {
    @State private var referralCode = "SC40-SPEED123"
    @State private var showingShareSheet = false
    @State private var referralCount = 3
    @State private var earnedRewards = 25.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Refer Friends")
                            .font(.title.bold())
                        
                        Text("Share Sprint Coach 40 and earn rewards for every friend who joins!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Referral Code Card
                    VStack(spacing: 16) {
                        Text("Your Referral Code")
                            .font(.headline)
                        
                        HStack {
                            Text(referralCode)
                                .font(.title2.monospaced().bold())
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Button("Copy") {
                                UIPasteboard.general.string = referralCode
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .padding(.horizontal)
                    
                    // Stats
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(referralCount)")
                                .font(.title.bold())
                                .foregroundColor(.blue)
                            Text("Referrals")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack {
                            Text("$\(earnedRewards, specifier: "%.0f")")
                                .font(.title.bold())
                                .foregroundColor(.green)
                            Text("Earned")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 2)
                    )
                    .padding(.horizontal)
                    
                    // How it Works
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How It Works")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                Text("1.")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Text("Share your referral code with friends")
                                    .font(.subheadline)
                            }
                            
                            HStack(alignment: .top) {
                                Text("2.")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Text("They sign up and enter your code")
                                    .font(.subheadline)
                            }
                            
                            HStack(alignment: .top) {
                                Text("3.")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Text("You both get $5 credit and premium features")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    
                    // Share Button
                    Button("Share with Friends") {
                        showingShareSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Referrals")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [
                "Join me on Sprint Coach 40 and improve your speed! Use my referral code \(referralCode) to get started with premium features. Download now!"
            ])
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ReferralsView()
}

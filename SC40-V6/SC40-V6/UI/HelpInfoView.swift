import SwiftUI

struct HelpInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showMessageSheet = false
    @State private var helpTopics = [
        // Feedback & Support (Sprint Coach 40)
        "Cancel Membership/Subscription",
        "Refund",
        "Restore a Membership/Subscription",
        "Change Membership to Lifetime",
        "Reset Plan",
        "What Does Lifetime Membership Mean?",
        "Lost History or Progress",
        "Apple Watch Sync",
        "Apple Watch: Spotify & Bluetooth Headphones",
        "Apple Watch: Apple Music & Bluetooth Headphones"
    ]
    var body: some View {
        NavigationView {
            ZStack {
                // Help & Support Canvas liquid glass background
                Canvas { context, size in
                    // Support theme gradient
                    let helpGradient = Gradient(colors: [
                        Color.brandBackground.opacity(0.95),
                        Color.blue.opacity(0.4),
                        Color.purple.opacity(0.3),
                        Color.indigo.opacity(0.25)
                    ])
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(helpGradient,
                                            startPoint: CGPoint(x: 0, y: 0),
                                            endPoint: CGPoint(x: size.width, y: size.height))
                    )
                    
                    // Support icon elements
                    let supportElements = 8
                    for i in 0..<supportElements {
                        let x = size.width * (0.15 + CGFloat(i % 3) * 0.35)
                        let y = size.height * (0.2 + CGFloat(i / 3) * 0.3)
                        let radius: CGFloat = 18 + CGFloat(i % 4) * 6
                        
                        // Help bubbles
                        context.addFilter(.blur(radius: 14))
                        context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                                   with: .color(Color.blue.opacity(0.16)))
                        
                        // Question mark visualization
                        if i % 3 == 0 {
                            context.fill(Path(ellipseIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)),
                                       with: .color(Color.white.opacity(0.8)))
                        }
                    }
                    
                    // Support wave patterns
                    let waveHeight: CGFloat = 12
                    let waveLength = size.width / 4
                    var wavePath = Path()
                    wavePath.move(to: CGPoint(x: 0, y: size.height * 0.75))
                    for x in stride(from: 0, through: size.width, by: 2) {
                        let y = size.height * 0.75 + waveHeight * sin((x / waveLength) * 2 * .pi)
                        wavePath.addLine(to: CGPoint(x: x, y: y))
                    }
                    wavePath.addLine(to: CGPoint(x: size.width, y: size.height))
                    wavePath.addLine(to: CGPoint(x: 0, y: size.height))
                    
                    context.fill(wavePath, with: .color(Color.purple.opacity(0.12)))
                    
                    // Glass overlay
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .color(Color.white.opacity(0.03))
                    )
                }
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button("Close") { presentationMode.wrappedValue.dismiss() }
                            .foregroundColor(.brandPrimary)
                        Spacer()
                        Text("Feedback & Support")
                            .font(.headline)
                            .foregroundColor(.brandAccent)
                        Spacer()
                        Spacer().frame(width: 60)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    Divider()
                    Button(action: { showMessageSheet = true }) {
                        Text("Send us a message")
                            .foregroundColor(.brandTertiary)
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                    }
                    Divider()
                    HStack {
                        Text("40 Yard Sprinter (IOS)")
                            .font(.subheadline)
                            .foregroundColor(.brandAccent)
                            .padding(.leading)
                        Spacer()
                    }
                    .padding(.top, 8)
                    List {
                        ForEach(helpTopics, id: \.self) { topic in
                            NavigationLink(destination: HelpTopicDetailView(topic: topic)) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.brandTertiary)
                                    Text(topic)
                                        .foregroundColor(.brandSecondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        Button("Load more") {}
                            .foregroundColor(.brandTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listStyle(PlainListStyle())
                    VStack(spacing: 2) {
                        Text("Sprint Coach 40")
                            .font(.footnote)
                            .foregroundColor(.brandAccent)
                        Text("support@sprintcoach40.com")
                            .font(.footnote)
                            .foregroundColor(.brandAccent)
                    }
                    .padding(.bottom, 8)
                }
            }
            .sheet(isPresented: $showMessageSheet) {
                MessageSheet()
            }
        }
    }
}

struct HelpTopicDetailView: View {
    var topic: String
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(topic)
                    .font(.title2.bold())
                    .padding(.top)
                Group {
                    if topic == "Cancel Membership/Subscription" {
                        Text("To cancel your Sprint Coach 40 membership or subscription, go to your Apple ID subscriptions in Settings, select Sprint Coach 40, and tap 'Cancel Subscription'. For help, contact Accelerate support.")
                    } else if topic == "Refund" {
                        Text("Refunds are processed through the App Store. Open your Apple receipt email and follow the 'Report a Problem' link, or visit reportaproblem.apple.com. For issues, contact Accelerate support.")
                    } else if topic == "Restore a Membership/Subscription" {
                        Text("To restore a previous purchase, go to Settings > Profile > Restore Purchases in the Sprint Coach 40 app. Make sure you're signed in with the same Apple ID.")
                    } else if topic == "Change Membership to Lifetime" {
                        Text("To upgrade to a Lifetime Membership, visit the Pro Features section in the app and select 'Upgrade to Lifetime'.")
                    } else if topic == "Reset Plan" {
                        Text("To reset your training plan, go to Settings > Training Plan > Reset. This will clear your current progress and start a new plan.")
                    } else if topic == "What Does Lifetime Membership Mean?" {
                        Text("Lifetime Membership gives you unlimited access to all Sprint Coach 40 features, updates, and Pro content for a one-time fee.")
                    } else if topic == "How do I update my payment method?" {
                        Text("Update your payment method in your Apple ID settings under Payment & Shipping. The app uses your Apple account for all purchases.")
                    } else if topic == "How do I change my email address?" {
                        Text("Your email address is managed through your Apple ID. For in-app communications, update your profile in Settings > Profile.")
                    } else if topic == "How do I change my password?" {
                        Text("Sprint Coach 40 uses your Apple ID for authentication. Change your password in your Apple ID settings.")
                    } else if topic == "Lost History or Progress" {
                        Text("If you lost your training history, ensure you're signed in with the correct Apple ID and iCloud is enabled. For further help, contact Accelerate support.")
                    } else if topic == "How do I backup or export my data?" {
                        Text("Your data is automatically backed up with iCloud if enabled. To export, use the History > Export PDF feature in the app.")
                    } else if topic == "How do I sync my data across devices?" {
                        Text("Enable iCloud sync in Settings. Make sure you're signed in with the same Apple ID on all devices.")
                    } else if topic == "How do I start a new training plan?" {
                        Text("Go to the Training tab and tap 'Start New Plan'. You can select your level and goals.")
                    } else if topic == "How do I adjust my training level?" {
                        Text("Adjust your training level in Settings > Coaching Settings. Choose Beginner, Intermediate, Advanced, or Pro.")
                    } else if topic == "How do I set reminders or notifications?" {
                        Text("Set reminders in Settings > Reminders. Enable push notifications in iOS Settings > Notifications > Sprint Coach 40.")
                    } else if topic == "How do I use the 40 Yard Smart Hub?" {
                        Text("Access the Smart Hub from the main menu for sprinting guidance, drills, form tips, and more.")
                    } else if topic == "How do I join the Leaderboard?" {
                        Text("Opt in to the Leaderboard in Settings > Profile. Your best times will be ranked with other US sprinters.")
                    } else if topic == "Apple Watch Sync" {
                        Text("To sync with Apple Watch, ensure Bluetooth is enabled and both devices are signed in to the same Apple ID. Open the Watch app and follow the pairing instructions.")
                    } else if topic == "Apple Watch: Spotify & Bluetooth Headphones" {
                        Text("Connect your Bluetooth headphones in the Watch's Settings > Bluetooth. Use Spotify on your Watch for music during workouts.")
                    } else if topic == "Apple Watch: Apple Music & Bluetooth Headphones" {
                        Text("Connect your Bluetooth headphones in the Watch's Settings > Bluetooth. Use Apple Music on your Watch for music during workouts.")
                    } else if topic == "Apple Watch: Troubleshooting" {
                        Text("If you have issues syncing, restart both your iPhone and Watch, and ensure both apps are up to date.")
                    } else if topic == "Contact Support" {
                        Text("For direct support, use the 'Send us a message' button or email support@sprintcoach40.com.")
                    } else if topic == "App not working as expected" {
                        Text("Try restarting the app and your device. If issues persist, contact Accelerate support with details.")
                    } else if topic == "How do I report a bug or suggest a feature?" {
                        Text("Use the 'Send us a message' button to contact Accelerate with your feedback or suggestions.")
                    } else if topic == "How do I delete my account?" {
                        Text("To delete your account and all data, contact support@sprintcoach40.com with your request.")
                    } else if topic == "Privacy Policy & Data Security" {
                        Text("View our privacy policy in Settings > Privacy or at sprintcoach40.com/privacy. Your data is protected and never sold.")
                    } else {
                        Text("Detailed information coming soon.")
                            .foregroundColor(.brandAccent)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            .background(Color.brandBackground.edgesIgnoringSafeArea(.all))
        }
    }
}

struct MessageSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var message = ""
    var body: some View {
        NavigationView {
            VStack {
                Text("Send us a message to Accelerate Support")
                    .font(.headline)
                    .padding(.top)
                TextEditor(text: $message)
                    .frame(height: 180)
                    .padding()
                    .background(Color.brandAccent.opacity(0.1))
                    .cornerRadius(12)
                Button(action: { 
                    // Here you would send the message to Accelerate's backend or support email
                    presentationMode.wrappedValue.dismiss() 
                }) {
                    Text("Send")
                        .font(.headline)
                        .foregroundColor(.brandBackground)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.brandPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                Spacer()
            }
            .padding()
            .background(Color.brandBackground.edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
        }
    }
}

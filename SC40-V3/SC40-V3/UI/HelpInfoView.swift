import SwiftUI

struct HelpInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var showMessageSheet = false
    @State private var showFAQ = false
    @State private var showGettingStarted = false
    @State private var showSubscriptionBilling = false
    @State private var showAccountManagement = false
    @State private var showTrainingWorkouts = false
    @State private var showTechnicalSupport = false
    @State private var showAboutApp = false
    @State private var showLegalPrivacy = false
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background matching Settings
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 0.0),
                        .init(color: Color(red: 0.1, green: 0.2, blue: 0.35), location: 0.3),
                        .init(color: Color(red: 0.15, green: 0.25, blue: 0.45), location: 0.5),
                        .init(color: Color(red: 0.2, green: 0.15, blue: 0.35), location: 0.7),
                        .init(color: Color(red: 0.1, green: 0.05, blue: 0.25), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 16) {
                            // Help Icon
                            ZStack {
                                Circle()
                                    .fill(Color(red: 1.0, green: 0.8, blue: 0.0))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .padding(.top, 20)
                            
                            VStack(spacing: 8) {
                                Text("Help & Info")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Get support and learn more about Sprint Coach 40")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.bottom, 40)
                        
                        // Quick Actions Section
                        HelpSection(
                            icon: "envelope.fill",
                            title: "Quick Actions",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0)
                        ) {
                            VStack(spacing: 12) {
                                HelpActionButton(
                                    icon: "paperplane.fill",
                                    title: "Send us a message",
                                    subtitle: "Get direct support from our team",
                                    action: { showMessageSheet = true }
                                )
                                
                                HelpActionButton(
                                    icon: "questionmark.circle.fill",
                                    title: "Frequently Asked Questions",
                                    subtitle: "Find quick answers to common questions",
                                    action: { showFAQ = true }
                                )
                            }
                        }
                        
                        // Getting Started Section
                        HelpSection(
                            icon: "play.circle.fill",
                            title: "Getting Started",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0)
                        ) {
                            VStack(spacing: 12) {
                                HelpNavigationButton(
                                    icon: "figure.run",
                                    title: "Getting Started Guide",
                                    subtitle: "Learn the basics of Sprint Coach 40",
                                    action: { showGettingStarted = true }
                                )
                                
                                HelpNavigationButton(
                                    icon: "dumbbell.fill",
                                    title: "Training & Workouts",
                                    subtitle: "Master your sprint training",
                                    action: { showTrainingWorkouts = true }
                                )
                            }
                        }
                        
                        // Account & Billing Section
                        HelpSection(
                            icon: "person.circle.fill",
                            title: "Account & Billing",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0)
                        ) {
                            VStack(spacing: 12) {
                                HelpNavigationButton(
                                    icon: "creditcard.fill",
                                    title: "Subscription & Billing",
                                    subtitle: "Manage your subscription",
                                    action: { showSubscriptionBilling = true }
                                )
                                
                                HelpNavigationButton(
                                    icon: "person.crop.circle.fill",
                                    title: "Account Management",
                                    subtitle: "Profile and account settings",
                                    action: { showAccountManagement = true }
                                )
                            }
                        }
                        
                        // Support & Information Section
                        HelpSection(
                            icon: "gear.circle.fill",
                            title: "Support & Information",
                            iconColor: Color(red: 1.0, green: 0.8, blue: 0.0)
                        ) {
                            VStack(spacing: 12) {
                                HelpNavigationButton(
                                    icon: "wrench.and.screwdriver.fill",
                                    title: "Technical Support",
                                    subtitle: "Troubleshooting and technical help",
                                    action: { showTechnicalSupport = true }
                                )
                                
                                HelpNavigationButton(
                                    icon: "info.circle.fill",
                                    title: "About Sprint Coach 40",
                                    subtitle: "Learn about our app and mission",
                                    action: { showAboutApp = true }
                                )
                                
                                HelpNavigationButton(
                                    icon: "doc.text.fill",
                                    title: "Legal & Privacy",
                                    subtitle: "Terms, privacy policy, and legal info",
                                    action: { showLegalPrivacy = true }
                                )
                            }
                        }
                        
                        // Contact Information
                        VStack(spacing: 12) {
                            Text("Sprint Coach 40")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("support@sprintcoach40.com")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                            
                            Text("Version 1.0.0")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showContent = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showMessageSheet) {
            MessageSheet()
        }
        .sheet(isPresented: $showFAQ) {
            FAQView()
        }
        .sheet(isPresented: $showGettingStarted) {
            GettingStartedView()
        }
        .sheet(isPresented: $showSubscriptionBilling) {
            SubscriptionBillingView()
        }
        .sheet(isPresented: $showAccountManagement) {
            AccountManagementView()
        }
        .sheet(isPresented: $showTrainingWorkouts) {
            TrainingWorkoutsView()
        }
        .sheet(isPresented: $showTechnicalSupport) {
            TechnicalSupportView()
        }
        .sheet(isPresented: $showAboutApp) {
            AboutAppView()
        }
        .sheet(isPresented: $showLegalPrivacy) {
            LegalPrivacyView()
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

// MARK: - Help Components

struct HelpSection<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    let content: Content
    
    init(icon: String, title: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Section Content
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }
}

struct HelpActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct HelpNavigationButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

struct MessageSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @State private var email = ""
    @State private var subject = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium gradient background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.05, green: 0.1, blue: 0.2), location: 0.0),
                        .init(color: Color(red: 0.1, green: 0.2, blue: 0.35), location: 0.3),
                        .init(color: Color(red: 0.15, green: 0.25, blue: 0.45), location: 0.5),
                        .init(color: Color(red: 0.2, green: 0.15, blue: 0.35), location: 0.7),
                        .init(color: Color(red: 0.1, green: 0.05, blue: 0.25), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Text("📧 Contact Support")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Send us a message and we'll get back to you")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                TextField("your.email@example.com", text: $email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Subject")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                TextField("Brief description of your issue", text: $subject)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Message")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                TextEditor(text: $message)
                                    .frame(height: 120)
                                    .padding(8)
                                    .background(Color.white)
                                    .cornerRadius(8)
                            }
                        }
                        
                        Button(action: {
                            // Send message logic here
                            HapticManager.shared.success()
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Send Message")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(message.isEmpty || email.isEmpty || subject.isEmpty)
                        .opacity(message.isEmpty || email.isEmpty || subject.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

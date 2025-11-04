import SwiftUI

// MARK: - FAQ View

struct FAQView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var helpContent = HelpContentManager.shared
    
    var faqItems: [HelpFAQItem] {
        return helpContent.getCurrentFAQContent()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
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
                    LazyVStack(spacing: 16) {
                        ForEach(faqItems) { item in
                            FAQCard(item: item)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct FAQCard: View {
    let item: HelpFAQItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                HapticManager.shared.light()
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(item.question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(item.answer)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.12), location: 0.0),
                            .init(color: Color.white.opacity(0.06), location: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Getting Started View

struct GettingStartedView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
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
                            Text("🏃‍♂️ Getting Started")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Your complete guide to Sprint Coach 40")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            HelpArticleCard(
                                title: "Setting Up Your Profile",
                                content: "Complete your profile with accurate height, weight, age, and fitness level. This helps Sprint Coach 40 provide personalized training recommendations and accurate performance analysis."
                            )
                            
                            HelpArticleCard(
                                title: "Your First Sprint Session",
                                content: "Start with a proper warm-up, find a flat 40-yard distance, and follow the app's timing instructions. Hold your phone steady and start running when prompted."
                            )
                            
                            HelpArticleCard(
                                title: "Understanding Your Results",
                                content: "Your 40-yard time is displayed immediately after each sprint. Track improvements over time and compare with position-specific benchmarks in the Analytics section."
                            )
                            
                            HelpArticleCard(
                                title: "Training Programs Explained",
                                content: "Choose from Beginner, Intermediate, Advanced, or Pro programs. Each includes progressive workouts designed to improve your speed, form, and overall performance."
                            )
                            
                            HelpArticleCard(
                                title: "Using the 40 Yard Smart Hub",
                                content: "Access expert knowledge on sprinting technique, training drills, nutrition, and equipment. This comprehensive resource helps you train smarter and faster."
                            )
                            
                            HelpArticleCard(
                                title: "Apple Watch Integration",
                                content: "Pair your Apple Watch for heart rate monitoring, workout tracking, and convenient wrist-based controls during training sessions."
                            )
                            
                            HelpArticleCard(
                                title: "Safety Guidelines",
                                content: "Always warm up before sprinting, train on safe surfaces, stay hydrated, and listen to your body. Stop if you feel pain or excessive fatigue."
                            )
                            
                            HelpArticleCard(
                                title: "Maximizing Your Progress",
                                content: "Train consistently, focus on proper form, track your nutrition, get adequate rest, and gradually increase training intensity following the app's recommendations."
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Getting Started")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Subscription & Billing View

struct SubscriptionBillingView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var helpContent = HelpContentManager.shared
    
    var subscriptionArticles: [HelpArticle] {
        return helpContent.getCurrentSubscriptionContent()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
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
                            Text("💳 Subscription & Billing")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Manage your Sprint Coach 40 subscription")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Last updated: \(helpContent.lastUpdated, formatter: DateFormatter.shortDate)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            ForEach(subscriptionArticles, id: \.title) { article in
                                HelpArticleCard(
                                    title: article.title,
                                    content: article.content
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Subscription & Billing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Account Management View

struct AccountManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
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
                            Text("👤 Account Management")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Manage your Sprint Coach 40 account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            HelpArticleCard(
                                title: "Creating Your Profile",
                                content: "Set up your complete athlete profile with personal information, fitness level, training goals, and preferences. This helps Sprint Coach 40 provide personalized recommendations."
                            )
                            
                            HelpArticleCard(
                                title: "Updating Personal Information",
                                content: "Keep your profile current by updating height, weight, age, and fitness level in Settings > Profile. Accurate information ensures better training recommendations and progress tracking."
                            )
                            
                            HelpArticleCard(
                                title: "Privacy Settings",
                                content: "Control your data sharing preferences, leaderboard participation, and social features. Access privacy settings through Settings > Profile > Privacy Options."
                            )
                            
                            HelpArticleCard(
                                title: "Data Export & Backup",
                                content: "Export your training data, performance history, and progress reports. Your data is automatically backed up to iCloud when enabled in iOS Settings."
                            )
                            
                            HelpArticleCard(
                                title: "Account Security",
                                content: "Sprint Coach 40 uses Apple ID authentication for maximum security. Your account is protected by Apple's security infrastructure and two-factor authentication."
                            )
                            
                            HelpArticleCard(
                                title: "Switching Devices",
                                content: "Your data syncs across all devices signed in with the same Apple ID. Install Sprint Coach 40 on your new device and sign in to access your complete training history."
                            )
                            
                            HelpArticleCard(
                                title: "Deleting Your Account",
                                content: "To permanently delete your account and all associated data, contact support@sprintcoach40.com. This action cannot be undone and will remove all training history."
                            )
                            
                            HelpArticleCard(
                                title: "Account Recovery",
                                content: "If you lose access to your account, ensure you're signed in with the correct Apple ID. For additional help, contact Sprint Coach 40 support with your account details."
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Account Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Training & Workouts View

struct TrainingWorkoutsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
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
                            Text("🏃‍♂️ Training & Workouts")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Master your sprint training with Sprint Coach 40")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            HelpArticleCard(
                                title: "Training Program Overview",
                                content: "Sprint Coach 40 offers progressive 12-week programs for all fitness levels. Each program includes warm-ups, sprint drills, strength exercises, and cool-downs designed by professional coaches."
                            )
                            
                            HelpArticleCard(
                                title: "Proper Sprint Technique",
                                content: "Learn the fundamentals of efficient sprinting: proper start position, acceleration mechanics, arm swing, stride frequency, and finishing technique. Access detailed guides in the 40 Yard Smart hub."
                            )
                            
                            HelpArticleCard(
                                title: "Workout Structure",
                                content: "Each session includes: 10-minute dynamic warm-up, technique drills, sprint repetitions, strength training, and 10-minute cool-down. Sessions typically last 45-60 minutes."
                            )
                            
                            HelpArticleCard(
                                title: "Progressive Training",
                                content: "Programs gradually increase intensity and volume. Week 1-4: Foundation building, Week 5-8: Speed development, Week 9-12: Peak performance and testing."
                            )
                            
                            HelpArticleCard(
                                title: "Recovery and Rest Days",
                                content: "Rest days are crucial for adaptation and injury prevention. Follow the recommended schedule: 3-4 training days per week with at least one full rest day between intense sessions."
                            )
                            
                            HelpArticleCard(
                                title: "Tracking Your Progress",
                                content: "Monitor improvements through regular 40-yard time trials, split time analysis, consistency scores, and weekly volume tracking. Set realistic goals and celebrate achievements."
                            )
                            
                            HelpArticleCard(
                                title: "Injury Prevention",
                                content: "Always warm up thoroughly, maintain proper form, listen to your body, and don't train through pain. Include mobility work, strength training, and adequate sleep in your routine."
                            )
                            
                            HelpArticleCard(
                                title: "Advanced Training Techniques",
                                content: "Pro users access advanced methods: overspeed training, resistance sprints, plyometric progressions, video analysis, and personalized coaching feedback."
                            )
                            
                            HelpArticleCard(
                                title: "Competition Preparation",
                                content: "Prepare for combines, tryouts, or competitions with specialized peaking programs, mental preparation techniques, and performance optimization strategies."
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Training & Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Technical Support View

struct TechnicalSupportView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var helpContent = HelpContentManager.shared
    
    var technicalArticles: [HelpArticle] {
        return helpContent.getCurrentTechnicalContent()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
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
                            Text("🔧 Technical Support")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Troubleshooting and technical assistance")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Content version: \(helpContent.contentVersion)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            ForEach(technicalArticles, id: \.title) { article in
                                HelpArticleCard(
                                    title: article.title,
                                    content: article.content
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Technical Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            helpContent.checkForUpdates()
        }
    }
}

// MARK: - About App View

struct AboutAppView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
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
                            Text("ℹ️ About Sprint Coach 40")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Professional sprint training in your pocket")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            HelpArticleCard(
                                title: "Our Mission",
                                content: "Sprint Coach 40 democratizes elite sprint training, making professional coaching techniques accessible to athletes at every level. We believe everyone deserves the opportunity to reach their speed potential."
                            )
                            
                            HelpArticleCard(
                                title: "App Features",
                                content: "GPS-based 40-yard timing, progressive training programs, advanced analytics, form analysis, Apple Watch integration, leaderboards, and comprehensive educational content from professional coaches."
                            )
                            
                            HelpArticleCard(
                                title: "Scientific Foundation",
                                content: "Our training methods are based on peer-reviewed sports science research, biomechanical analysis, and proven techniques used by Olympic and professional athletes worldwide."
                            )
                            
                            HelpArticleCard(
                                title: "Development Team",
                                content: "Created by certified strength and conditioning specialists, former collegiate and professional athletes, and experienced app developers passionate about athletic performance."
                            )
                            
                            HelpArticleCard(
                                title: "Version History",
                                content: "Version 1.0.0 introduces core timing functionality, training programs, and analytics. Regular updates add new features, improve accuracy, and expand educational content."
                            )
                            
                            HelpArticleCard(
                                title: "Awards & Recognition",
                                content: "Featured by Apple as 'App of the Day', recognized by sports performance professionals, and trusted by thousands of athletes from high school to professional levels."
                            )
                            
                            HelpArticleCard(
                                title: "Community Impact",
                                content: "Sprint Coach 40 has helped athletes improve their 40-yard times by an average of 0.3 seconds, earn college scholarships, and achieve their athletic dreams through dedicated training."
                            )
                            
                            HelpArticleCard(
                                title: "Future Development",
                                content: "Upcoming features include AI-powered form analysis, virtual reality training, team management tools, and integration with professional scouting platforms."
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("About Sprint Coach 40")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Legal & Privacy View

struct LegalPrivacyView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var helpContent = HelpContentManager.shared
    
    var privacyArticles: [HelpArticle] {
        return helpContent.getCurrentPrivacyContent()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
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
                            Text("📄 Legal & Privacy")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Your privacy and legal rights matter to us")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Compliance updated: \(helpContent.lastUpdated, formatter: DateFormatter.shortDate)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            ForEach(privacyArticles, id: \.title) { article in
                                HelpArticleCard(
                                    title: article.title,
                                    content: article.content
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Legal & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            helpContent.checkForUpdates()
        }
    }
}

// MARK: - Help Article Card Component

struct HelpArticleCard: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(content)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.12), location: 0.0),
                            .init(color: Color.white.opacity(0.06), location: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

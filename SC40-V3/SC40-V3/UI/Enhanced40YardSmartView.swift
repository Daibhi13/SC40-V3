import SwiftUI

// MARK: - Smart Hub Article Types
enum SmartHubArticleType: String, CaseIterable, Identifiable {
    case sprintTrainingGuidance = "Sprint Training Guidance"
    case essentialSprintDrills = "Essential Sprint Drills"
    case plyometricsForSprinters = "Plyometrics for Sprinters"
    case perfectSprintForm = "Perfect Sprint Form"
    case nutritionForSpeed = "Nutrition for Speed"
    case sprintGearGuide = "Sprint Gear Guide"
    
    var id: String { rawValue }
}

// MARK: - 40 Yard Smart Hub
struct Enhanced40YardSmartView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedArticle: SmartHubArticleType? = nil
    @State private var showArticle = false
    
    var body: some View {
        ZStack {
            // Professional gradient background matching the design
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.3, blue: 0.6),
                    Color(red: 0.3, green: 0.4, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 20) {
                        // Close Button
                        HStack {
                            Spacer()
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Icon and Title
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.yellow)
                            }
                            
                            VStack(spacing: 8) {
                                Text("40 Yard Smart")
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                                
                                Text("Expert Knowledge & Video Tutorials")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                    
                    // Content Cards
                    VStack(spacing: 20) {
                        EnhancedSmartHubCard(
                            icon: "figure.run",
                            iconColor: .yellow,
                            title: "Sprint Training Guidance",
                            subtitle: "How to approach sprint training, set goals, and stay motivated.",
                            hasVideo: true
                        ) {
                            selectedArticle = .sprintTrainingGuidance
                            showArticle = true
                        }
                        
                        EnhancedSmartHubCard(
                            icon: "bolt.fill",
                            iconColor: .orange,
                            title: "Essential Sprint Drills",
                            subtitle: "Key drills to improve speed, mechanics, and explosiveness.",
                            hasVideo: true
                        ) {
                            selectedArticle = .essentialSprintDrills
                            showArticle = true
                        }
                        
                        EnhancedSmartHubCard(
                            icon: "flame.fill",
                            iconColor: .red,
                            title: "Plyometrics for Sprinters",
                            subtitle: "Explosive power exercises that build speed and strength.",
                            hasVideo: true
                        ) {
                            selectedArticle = .plyometricsForSprinters
                            showArticle = true
                        }
                        
                        EnhancedSmartHubCard(
                            icon: "figure.walk",
                            iconColor: .green,
                            title: "Perfect Sprint Form",
                            subtitle: "Master the fundamentals of efficient sprinting technique.",
                            hasVideo: true
                        ) {
                            selectedArticle = .perfectSprintForm
                            showArticle = true
                        }
                        
                        EnhancedSmartHubCard(
                            icon: "leaf.fill",
                            iconColor: .green,
                            title: "Nutrition for Speed",
                            subtitle: "Fuel your body for peak performance and recovery.",
                            hasVideo: true
                        ) {
                            selectedArticle = .nutritionForSpeed
                            showArticle = true
                        }
                        
                        EnhancedSmartHubCard(
                            icon: "tshirt.fill",
                            iconColor: .blue,
                            title: "Sprint Gear Guide",
                            subtitle: "Choose the right clothing and equipment for training.",
                            hasVideo: true
                        ) {
                            selectedArticle = .sprintGearGuide
                            showArticle = true
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showArticle) {
            if let article = selectedArticle {
                SmartHubArticleView(articleType: article)
            }
        }
    }
}

// MARK: - Enhanced Smart Hub Card Component
struct EnhancedSmartHubCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let hasVideo: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                }
                
                Spacer()
                
                // Videos Soon Badge
                if hasVideo {
                    HStack(spacing: 6) {
                        Image(systemName: "video.circle.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Videos Soon")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            Button(action: action) {
                HStack(spacing: 8) {
                    Text("READ")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                        .font(.subheadline)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Smart Hub Article View
struct SmartHubArticleView: View {
    let articleType: SmartHubArticleType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: iconForArticle)
                                .font(.title)
                                .foregroundColor(colorForArticle)
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Image(systemName: "video.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text("Videos Soon")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                        
                        Text(articleType.rawValue)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(subtitleForArticle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Content Section
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(contentSections, id: \.title) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(section.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(section.content)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineSpacing(4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var iconForArticle: String {
        switch articleType {
        case .sprintTrainingGuidance: return "figure.run"
        case .essentialSprintDrills: return "bolt.fill"
        case .plyometricsForSprinters: return "flame.fill"
        case .perfectSprintForm: return "figure.walk"
        case .nutritionForSpeed: return "leaf.fill"
        case .sprintGearGuide: return "tshirt.fill"
        }
    }
    
    private var colorForArticle: Color {
        switch articleType {
        case .sprintTrainingGuidance: return .yellow
        case .essentialSprintDrills: return .orange
        case .plyometricsForSprinters: return .red
        case .perfectSprintForm: return .green
        case .nutritionForSpeed: return .green
        case .sprintGearGuide: return .blue
        }
    }
    
    private var subtitleForArticle: String {
        switch articleType {
        case .sprintTrainingGuidance: return "Expert guidance on training methodology, goal setting, and motivation"
        case .essentialSprintDrills: return "Professional drills to improve speed, mechanics, and explosiveness"
        case .plyometricsForSprinters: return "Power development exercises for explosive sprint performance"
        case .perfectSprintForm: return "Master the biomechanics of efficient sprinting technique"
        case .nutritionForSpeed: return "Fuel your body for peak performance and optimal recovery"
        case .sprintGearGuide: return "Professional equipment and clothing recommendations"
        }
    }
    
    private var contentSections: [ContentSection] {
        switch articleType {
        case .sprintTrainingGuidance:
            return sprintTrainingGuidanceContent
        case .essentialSprintDrills:
            return essentialSprintDrillsContent
        case .plyometricsForSprinters:
            return plyometricsContent
        case .perfectSprintForm:
            return sprintFormContent
        case .nutritionForSpeed:
            return nutritionContent
        case .sprintGearGuide:
            return gearGuideContent
        }
    }
}

// MARK: - Content Section Model
struct ContentSection {
    let title: String
    let content: String
}

// MARK: - Article Content Data
extension SmartHubArticleView {
    
    var sprintTrainingGuidanceContent: [ContentSection] {
        [
            ContentSection(
                title: "Training Philosophy",
                content: "Sprint training is both an art and a science. Success comes from understanding that speed development requires patience, consistency, and intelligent progression. Your 40-yard dash time is a reflection of your power, technique, and mental preparation working in harmony."
            ),
            ContentSection(
                title: "Goal Setting Framework",
                content: "Set SMART goals for your sprint training:\n\n• Specific: Target exact time improvements (e.g., drop 0.1 seconds)\n• Measurable: Track weekly progress with consistent testing\n• Achievable: Aim for 2-5% improvements per training cycle\n• Relevant: Focus on your sport-specific speed needs\n• Time-bound: Set 8-12 week improvement cycles"
            ),
            ContentSection(
                title: "Training Frequency",
                content: "Optimal sprint training frequency depends on your experience level:\n\n• Beginners: 2-3 sessions per week with full recovery\n• Intermediate: 3-4 sessions with varied intensities\n• Advanced: 4-5 sessions with periodized planning\n\nAlways prioritize quality over quantity. One perfect sprint is worth more than ten sloppy ones."
            ),
            ContentSection(
                title: "Staying Motivated",
                content: "Motivation strategies for long-term success:\n\n• Track micro-improvements in technique and feel\n• Celebrate small wins and consistency streaks\n• Train with partners or groups when possible\n• Visualize your goals and competition scenarios\n• Remember that speed gains come in waves, not linear progression"
            ),
            ContentSection(
                title: "Recovery and Adaptation",
                content: "Your body adapts during recovery, not during training. Ensure adequate sleep (7-9 hours), proper nutrition, and active recovery days. Listen to your body - fatigue is the enemy of speed development."
            )
        ]
    }
    
    var essentialSprintDrillsContent: [ContentSection] {
        [
            ContentSection(
                title: "A-Skip Drill",
                content: "The foundation of sprint mechanics:\n\n• Drive knee to 90 degrees while maintaining tall posture\n• Land on the ball of your foot directly under your hip\n• Keep arms in sprinting position with opposite arm/leg coordination\n• Focus on quick ground contact and vertical lift\n• Perform 2-3 sets of 20 meters"
            ),
            ContentSection(
                title: "B-Skip Drill",
                content: "Advanced coordination and hamstring activation:\n\n• Start like A-skip, then extend leg forward and snap down\n• Emphasize the 'pawing' action to develop proper foot strike\n• Maintain rhythm and avoid over-reaching\n• Keep torso tall and core engaged\n• Perform 2-3 sets of 20 meters"
            ),
            ContentSection(
                title: "High Knees",
                content: "Hip flexor strength and sprint cadence:\n\n• Drive knees to waist height with rapid turnover\n• Stay on balls of feet with minimal ground contact\n• Pump arms in sprint rhythm\n• Maintain forward lean and avoid sitting back\n• Perform 3 sets of 15 seconds"
            ),
            ContentSection(
                title: "Butt Kicks",
                content: "Hamstring activation and recovery mechanics:\n\n• Rapidly bring heels to glutes while moving forward\n• Keep knees pointing down, not forward\n• Maintain sprint arm action\n• Focus on quick heel recovery\n• Perform 3 sets of 15 seconds"
            ),
            ContentSection(
                title: "Wall Drives",
                content: "Power development and drive phase mechanics:\n\n• Place hands on wall in sprint start position\n• Drive one knee up while pushing into wall\n• Alternate legs with explosive power\n• Keep supporting leg straight and strong\n• Perform 3 sets of 10 per leg"
            ),
            ContentSection(
                title: "Acceleration Runs",
                content: "Progressive speed development:\n\n• Start from various positions (standing, 3-point, blocks)\n• Accelerate smoothly through 30-40 meters\n• Focus on gradual rise to upright position\n• Maintain relaxation at top speed\n• Perform 4-6 runs with full recovery"
            )
        ]
    }
    
    var plyometricsContent: [ContentSection] {
        [
            ContentSection(
                title: "Power Development Principles",
                content: "Plyometrics develop the stretch-shortening cycle crucial for explosive sprinting. These exercises train your muscles to produce maximum force in minimum time, directly translating to faster acceleration and higher top speeds."
            ),
            ContentSection(
                title: "Box Jumps",
                content: "Vertical power development:\n\n• Start with 12-18 inch boxes, progress gradually\n• Focus on soft landings with bent knees\n• Step down, don't jump down to preserve joints\n• Emphasize explosive takeoff, not height\n• Perform 3-4 sets of 5-8 jumps"
            ),
            ContentSection(
                title: "Depth Jumps",
                content: "Reactive strength training:\n\n• Drop from 12-24 inch box\n• Land and immediately jump up or forward\n• Minimize ground contact time\n• Focus on quick reactive response\n• Perform 3-4 sets of 5-6 jumps"
            ),
            ContentSection(
                title: "Broad Jumps",
                content: "Horizontal power for acceleration:\n\n• Jump for maximum distance, not height\n• Use arm swing to generate momentum\n• Land with control and balance\n• Focus on triple extension (ankle, knee, hip)\n• Perform 3-4 sets of 5-8 jumps"
            ),
            ContentSection(
                title: "Single-Leg Bounds",
                content: "Unilateral power and coordination:\n\n• Bound forward on one leg for distance\n• Maintain balance and control\n• Alternate legs or perform sets per leg\n• Focus on powerful push-off and soft landing\n• Perform 3 sets of 6-8 bounds per leg"
            ),
            ContentSection(
                title: "Safety Guidelines",
                content: "Plyometric safety essentials:\n\n• Always warm up thoroughly before plyometrics\n• Start with low-intensity exercises and progress gradually\n• Ensure adequate recovery between sessions (48-72 hours)\n• Focus on quality over quantity\n• Stop when technique deteriorates or fatigue sets in"
            )
        ]
    }
    
    var sprintFormContent: [ContentSection] {
        [
            ContentSection(
                title: "Starting Position",
                content: "The foundation of a fast 40-yard dash:\n\n• 3-point stance: Weight evenly distributed\n• Front foot 6-8 inches behind start line\n• Back foot staggered for power\n• Hand placement for balance, not support\n• Eyes focused 5-10 yards ahead"
            ),
            ContentSection(
                title: "First Step Mechanics",
                content: "The most critical step in your 40:\n\n• Drive back leg powerfully into the ground\n• Keep low body angle (45 degrees) for first 10 yards\n• First step should be short and powerful\n• Pump arms aggressively for momentum\n• Avoid standing up too quickly"
            ),
            ContentSection(
                title: "Acceleration Phase (0-20 yards)",
                content: "Building speed efficiently:\n\n• Maintain forward lean with gradual rise\n• Drive knees forward and up\n• Push the ground behind you, not down\n• Keep head neutral, eyes forward\n• Arm swing should be powerful and rhythmic"
            ),
            ContentSection(
                title: "Maximum Velocity Phase (20-40 yards)",
                content: "Reaching and maintaining top speed:\n\n• Transition to upright running posture\n• Focus on quick ground contact\n• Maintain relaxation in face and shoulders\n• Keep stride length natural, increase turnover\n• Drive arms straight forward and back"
            ),
            ContentSection(
                title: "Arm Action",
                content: "Proper arm mechanics for maximum speed:\n\n• 90-degree bend at the elbow\n• Drive elbows back, hands come forward naturally\n• Keep hands relaxed, avoid clenching fists\n• Arms should not cross the midline of your body\n• Coordinate opposite arm with opposite leg"
            ),
            ContentSection(
                title: "Common Mistakes",
                content: "Avoid these speed-killing errors:\n\n• Standing up too quickly in acceleration\n• Over-striding and reaching with legs\n• Tensing up shoulders and facial muscles\n• Looking down or around during the run\n• Inconsistent arm action and timing"
            )
        ]
    }
    
    var nutritionContent: [ContentSection] {
        [
            ContentSection(
                title: "Pre-Training Nutrition",
                content: "Fuel for optimal performance:\n\n• Eat 2-3 hours before training for full meals\n• Include complex carbs for sustained energy\n• Moderate protein for muscle support\n• Avoid high fat and fiber foods before training\n• Stay hydrated throughout the day"
            ),
            ContentSection(
                title: "During Training",
                content: "Maintaining energy and hydration:\n\n• Sip water regularly, don't wait until thirsty\n• For sessions over 90 minutes, consider sports drinks\n• Avoid heavy foods during training\n• Listen to your body's hydration needs\n• Electrolyte balance is crucial in hot weather"
            ),
            ContentSection(
                title: "Post-Training Recovery",
                content: "Optimize recovery and adaptation:\n\n• Consume protein within 30 minutes (20-30g)\n• Include carbohydrates to replenish glycogen\n• Chocolate milk is an excellent recovery drink\n• Rehydrate with 150% of fluid lost through sweat\n• Focus on whole foods for micronutrients"
            ),
            ContentSection(
                title: "Daily Nutrition Strategy",
                content: "Building speed through consistent nutrition:\n\n• Eat 5-6 smaller meals throughout the day\n• Include lean protein at every meal\n• Prioritize colorful fruits and vegetables\n• Choose complex carbohydrates over simple sugars\n• Include healthy fats from nuts, fish, and avocados"
            ),
            ContentSection(
                title: "Supplements for Speed",
                content: "Evidence-based supplementation:\n\n• Creatine monohydrate (3-5g daily) for power\n• Caffeine (200-400mg) 30 minutes before training\n• Beta-alanine for muscular endurance\n• Vitamin D for bone health and muscle function\n• Always prioritize whole foods over supplements"
            ),
            ContentSection(
                title: "Hydration Guidelines",
                content: "Staying optimally hydrated:\n\n• Drink 16-20 oz of water 2-3 hours before training\n• Monitor urine color - aim for pale yellow\n• Weigh yourself before and after training\n• Replace 150% of weight lost through sweat\n• Include electrolytes for sessions over 60 minutes"
            )
        ]
    }
    
    var gearGuideContent: [ContentSection] {
        [
            ContentSection(
                title: "Sprint Spikes",
                content: "Choosing the right footwear:\n\n• Track spikes for maximum traction and speed\n• 6-8 spike pins for optimal grip\n• Lightweight construction for reduced energy cost\n• Proper fit - snug but not tight\n• Consider surface type (track vs. turf vs. grass)"
            ),
            ContentSection(
                title: "Training Shoes",
                content: "Daily training footwear essentials:\n\n• Lightweight running shoes for speed work\n• Good heel-to-toe drop for natural stride\n• Adequate cushioning for impact protection\n• Breathable materials for comfort\n• Replace every 300-500 miles"
            ),
            ContentSection(
                title: "Clothing Essentials",
                content: "Performance apparel for speed training:\n\n• Compression shorts or tights for muscle support\n• Moisture-wicking fabrics to stay dry\n• Lightweight, non-restrictive tops\n• Avoid cotton - choose synthetic materials\n• Layer appropriately for weather conditions"
            ),
            ContentSection(
                title: "Training Equipment",
                content: "Tools to enhance your speed development:\n\n• Resistance bands for activation and strength\n• Agility ladder for footwork and coordination\n• Cones for marking distances and drills\n• Stopwatch or timing system for progress tracking\n• Foam roller for recovery and mobility"
            ),
            ContentSection(
                title: "Technology Integration",
                content: "Modern tools for speed development:\n\n• GPS watches for pace and distance tracking\n• Video analysis apps for technique review\n• Heart rate monitors for training intensity\n• Sprint timing systems for accurate measurement\n• Recovery tracking devices for optimization"
            ),
            ContentSection(
                title: "Weather Considerations",
                content: "Adapting gear for conditions:\n\n• Cold weather: Layer system with base layers\n• Hot weather: Light colors and maximum ventilation\n• Rain: Water-resistant outer layers\n• Wind: Aerodynamic clothing for headwinds\n• Always prioritize safety and visibility"
            )
        ]
    }
}

#Preview {
    Enhanced40YardSmartView()
}

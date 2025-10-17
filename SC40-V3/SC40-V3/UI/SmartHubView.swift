// MARK: - Article Model
import Foundation
import SwiftUI

struct SmartHubArticle: Identifiable {
    let id = UUID()
    let title: String
    let image: String?
    let content: String
}

// MARK: - Article Content
enum SmartHubTopic: String, CaseIterable {
    case guidance, drills, plyometrics, form, diet, clothing, equipment, longevity
}

extension SmartHubTopic {
    var article: SmartHubArticle {
        switch self {
        case .guidance:
            return SmartHubArticle(
                title: "Guidance in Sprinting",
                image: "figure.run",
                content: """
Welcome to the 40 Yard SmartHub! Here you'll find guidance on how to approach sprint training, set goals, and stay motivated throughout your journey. Whether you're a beginner or a seasoned athlete, these resources will help you maximize your performance and enjoyment.
"""
            )
        case .drills:
            return SmartHubArticle(
                title: "Essential Sprint Drills",
                image: "bolt.circle",
                content: """
Sprint drills are the foundation of speed development. Learn about A-skips, B-skips, high knees, butt kicks, and more. These drills improve mechanics, coordination, and explosiveness.
"""
            )
        case .plyometrics:
            return SmartHubArticle(
                title: "Plyometrics for Sprinters",
                image: "flame",
                content: """
Plyometric exercises like box jumps, bounding, and hops build explosive power. Discover how to safely add plyometrics to your routine for maximum speed gains.
"""
            )
        case .form:
            return SmartHubArticle(
                title: "Sprinting Form Fundamentals",
                image: "figure.walk",
                content: """
Proper sprinting form is key to running faster and avoiding injury. Learn about posture, arm swing, stride length, and foot strike for optimal performance.
"""
            )
        case .diet:
            return SmartHubArticle(
                title: "Diet for Sprinters",
                image: "leaf",
                content: """
Nutrition fuels your training and recovery. Explore what to eat before, during, and after workouts to support sprint performance and overall health.
"""
            )
        case .clothing:
            return SmartHubArticle(
                title: "Clothing for Sprinting",
                image: "tshirt",
                content: """
The right clothing can enhance comfort and performance. Find out what to wear for different weather conditions and how to choose the best gear for sprinting.
"""
            )
        case .equipment:
            return SmartHubArticle(
                title: "Equipment for Sprinters",
                image: "sportscourt",
                content: """
From spikes to sleds, learn about the equipment that can help you train smarter and race faster.
"""
            )
        case .longevity:
            return SmartHubArticle(
                title: "Longevity in Sprinting",
                image: "heart.circle",
                content: """
Stay healthy and sprint for years to come. Tips on injury prevention, recovery, and maintaining motivation over the long term.
"""
            )
        }
    }
}

// MARK: - Article Detail View
struct ArticleDetailView: View {
    let article: SmartHubArticle
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let image = article.image {
                    Image(systemName: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                        .foregroundColor(.brandAccent)
                        .padding(.bottom, 8)
                }
                Text(article.title)
                    .font(.largeTitle.bold())
                    .foregroundColor(.brandPrimary)
                Text(article.content)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { presentationMode.wrappedValue.dismiss() }
            }
        }
    }
}

// MARK: - SmartHub Card
struct SmartHubCard: View {
    var image: String
    var title: String
    var description: String
    var buttonText: String
    var onRead: (() -> Void)? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !image.isEmpty {
                Image(systemName: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(description)
                .font(.body)
                .foregroundColor(.white.opacity(0.85))
            HStack {
                Spacer()
                Button(action: { onRead?() }) {
                    Text(buttonText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                        .background(Color(.darkGray))
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color(.darkGray))
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

// MARK: - Topic Card Views
struct GuidanceSmartView: View {
    @State private var showArticle = false
    var body: some View {
        SmartHubCard(
            image: SmartHubTopic.guidance.article.image ?? "",
            title: SmartHubTopic.guidance.article.title,
            description: "How to approach sprint training, set goals, and stay motivated.",
            buttonText: "READ",
            onRead: { showArticle = true }
        )
        .sheet(isPresented: $showArticle) {
            ArticleDetailView(article: SmartHubTopic.guidance.article)
        }
    }
}

struct DrillsSmartView: View {
    @State private var showArticle = false
    var body: some View {
        SmartHubCard(
            image: SmartHubTopic.drills.article.image ?? "",
            title: SmartHubTopic.drills.article.title,
            description: "Key drills to improve speed, mechanics, and explosiveness.",
            buttonText: "READ",
            onRead: { showArticle = true }
        )
        .sheet(isPresented: $showArticle) {
            ArticleDetailView(article: SmartHubTopic.drills.article)
        }
    }
}

struct PlyometricsSmartView: View {
    @State private var showArticle = false
    var body: some View {
        SmartHubCard(
            image: SmartHubTopic.plyometrics.article.image ?? "",
            title: SmartHubTopic.plyometrics.article.title,
            description: "Plyometric exercises to build explosive power.",
            buttonText: "READ",
            onRead: { showArticle = true }
        )
        .sheet(isPresented: $showArticle) {
            ArticleDetailView(article: SmartHubTopic.plyometrics.article)
        }
    }
}

struct FormSmartView: View {
    @State private var showArticle = false
    var body: some View {
        SmartHubCard(
            image: SmartHubTopic.form.article.image ?? "",
            title: SmartHubTopic.form.article.title,
            description: "Learn proper sprinting form for speed and injury prevention.",
            buttonText: "READ",
            onRead: { showArticle = true }
        )
        .sheet(isPresented: $showArticle) {
            ArticleDetailView(article: SmartHubTopic.form.article)
        }
    }
}

struct DietSmartView: View {
    @State private var showArticle = false
    var body: some View {
        SmartHubCard(
            image: SmartHubTopic.diet.article.image ?? "",
            title: SmartHubTopic.diet.article.title,
            description: "Nutrition tips for fueling sprint training and recovery.",
            buttonText: "READ",
            onRead: { showArticle = true }
        )
        .sheet(isPresented: $showArticle) {
            ArticleDetailView(article: SmartHubTopic.diet.article)
        }
    }
}

struct ClothingSmartView: View {
    @State private var showArticle = false
    var body: some View {
        SmartHubCard(
            image: SmartHubTopic.clothing.article.image ?? "",
            title: SmartHubTopic.clothing.article.title,
            description: "What to wear for comfort, performance, and weather.",
            buttonText: "READ",
            onRead: { showArticle = true }
        )
        .sheet(isPresented: $showArticle) {
            ArticleDetailView(article: SmartHubTopic.clothing.article)
        }
    }
}

struct EquipmentSmartView: View {
    @State private var showArticle = false
    var body: some View {
        SmartHubCard(
            image: SmartHubTopic.equipment.article.image ?? "",
            title: SmartHubTopic.equipment.article.title,
            description: "Gear and equipment to help you train and race.",
            buttonText: "READ",
            onRead: { showArticle = true }
        )
        .sheet(isPresented: $showArticle) {
            ArticleDetailView(article: SmartHubTopic.equipment.article)
        }
    }
}

struct LongevitySmartView: View {
    @State private var showArticle = false
    var body: some View {
        SmartHubCard(
            image: SmartHubTopic.longevity.article.image ?? "",
            title: SmartHubTopic.longevity.article.title,
            description: "How to stay healthy and sprint for years to come.",
            buttonText: "READ",
            onRead: { showArticle = true }
        )
        .sheet(isPresented: $showArticle) {
            ArticleDetailView(article: SmartHubTopic.longevity.article)
        }
    }
}

// MARK: - Main SmartHub View
struct SmartHubView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                // SmartHub Canvas liquid glass background
                Canvas { context, size in
                    // Knowledge hub gradient with educational theme
                    let smartGradient = Gradient(colors: [
                        Color.brandBackground.opacity(0.95),
                        Color.blue.opacity(0.4),
                        Color.cyan.opacity(0.3),
                        Color.green.opacity(0.25)
                    ])
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(smartGradient,
                                            startPoint: CGPoint(x: 0, y: 0),
                                            endPoint: CGPoint(x: size.width, y: size.height))
                    )
                    
                    // Educational elements floating
                    let knowledgeElements = 10
                    for i in 0..<knowledgeElements {
                        let x = size.width * (0.1 + CGFloat(i % 4) * 0.25)
                        let y = size.height * (0.15 + CGFloat(i / 4) * 0.3)
                        let radius: CGFloat = 15 + CGFloat(i % 3) * 10
                        
                        // Knowledge bubbles
                        context.addFilter(.blur(radius: 12))
                        context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                                   with: .color(Color.blue.opacity(0.18)))
                        
                        // Inner wisdom glow
                        context.fill(Path(ellipseIn: CGRect(x: x - radius * 0.4, y: y - radius * 0.4, width: radius * 0.8, height: radius * 0.8)),
                                   with: .color(Color.cyan.opacity(0.12)))
                    }
                    
                    // Learning wave patterns
                    let waveHeight: CGFloat = 15
                    let waveLength = size.width / 6
                    for waveIndex in 0..<4 {
                        let waveY = size.height * (0.2 + CGFloat(waveIndex) * 0.2)
                        var wavePath = Path()
                        wavePath.move(to: CGPoint(x: 0, y: waveY))
                        for x in stride(from: 0, through: size.width, by: 2) {
                            let y = waveY + waveHeight * sin((x / waveLength) * 2 * .pi + CGFloat(waveIndex) * .pi / 2)
                            wavePath.addLine(to: CGPoint(x: x, y: y))
                        }
                        wavePath.addLine(to: CGPoint(x: size.width, y: size.height))
                        wavePath.addLine(to: CGPoint(x: 0, y: size.height))
                        
                        let waveColors = [Color.green.opacity(0.12), Color.cyan.opacity(0.10), Color.blue.opacity(0.08), Color.purple.opacity(0.06)]
                        context.fill(wavePath, with: .color(waveColors[waveIndex]))
                    }
                    
                    // Glass overlay
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .color(Color.white.opacity(0.03))
                    )
                }
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                Text("40 Yard SmartHub")
                    .font(.largeTitle.bold())
                    .foregroundColor(.brandPrimary)
                    .padding(.top, 24)
                Text("Your sprinting knowledge hub. Tap a card to learn more.")
                    .font(.subheadline)
                    .foregroundColor(.brandSecondary)
                    .padding(.bottom, 12)
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 28) {
                        GuidanceSmartView()
                        DrillsSmartView()
                        PlyometricsSmartView()
                        FormSmartView()
                        DietSmartView()
                        ClothingSmartView()
                        EquipmentSmartView()
                        LongevitySmartView()
                    }
                }
            }
            }
        }
    }
}

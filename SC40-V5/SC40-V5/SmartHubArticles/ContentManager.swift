//
//  ContentManager.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import Foundation
import Combine

/// Manages content for SmartHub articles and resources
class ContentManager: ObservableObject {
    static let shared = ContentManager()

    @Published private(set) var articles: [Article] = []
    @Published private(set) var categories: [ArticleCategory] = []
    @Published private(set) var featuredArticles: [Article] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: Error?

    private let fileManager = FileManager.default
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    init() {
        loadLocalContent()
        setupCategories()
    }

    // MARK: - Content Loading

    /// Load local content from bundled files
    private func loadLocalContent() {
        isLoading = true

        // Load articles from JSON files in the bundle
        loadArticlesFromBundle()

        // Load featured articles
        loadFeaturedArticles()

        isLoading = false
    }

    /// Load articles from bundled JSON files
    private func loadArticlesFromBundle() {
        guard let bundleURL = Bundle.main.url(forResource: "Articles", withExtension: "json") else {
            return
        }

        do {
            let data = try Data(contentsOf: bundleURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let articleResponse = try decoder.decode(ArticleResponse.self, from: data)
            self.articles = articleResponse.articles
        } catch {
            lastError = error
            print("Failed to load articles: \(error.localizedDescription)")
        }
    }

    /// Load featured articles
    private func loadFeaturedArticles() {
        // Filter articles marked as featured
        featuredArticles = articles.filter { $0.isFeatured }
    }

    /// Setup article categories
    private func setupCategories() {
        categories = [
            ArticleCategory(id: UUID(), name: "Training Tips", icon: "figure.run", color: "blue", description: "Training techniques and tips"),
            ArticleCategory(id: UUID(), name: "Nutrition", icon: "leaf.fill", color: "green", description: "Nutrition and diet advice"),
            ArticleCategory(id: UUID(), name: "Recovery", icon: "bed.double.fill", color: "purple", description: "Recovery and rest strategies"),
            ArticleCategory(id: UUID(), name: "Technique", icon: "target", color: "orange", description: "Sprinting form and technique"),
            ArticleCategory(id: UUID(), name: "Psychology", icon: "brain.head.profile", color: "pink", description: "Mental training and mindset"),
            ArticleCategory(id: UUID(), name: "Injury Prevention", icon: "cross.case.fill", color: "red", description: "Injury prevention and safety"),
            ArticleCategory(id: UUID(), name: "Equipment", icon: "bag.fill", color: "brown", description: "Gear and equipment reviews")
        ]
    }

    // MARK: - Content Access

    /// Get articles for specific category
    func articlesForCategory(_ category: ArticleCategory) -> [Article] {
        return articles.filter { $0.categoryId == category.id }
    }

    /// Get article by ID
    func articleWithId(_ id: UUID) -> Article? {
        return articles.first { $0.id == id }
    }

    /// Search articles by title or content
    func searchArticles(query: String) -> [Article] {
        let lowercaseQuery = query.lowercased()
        return articles.filter {
            $0.title.lowercased().contains(lowercaseQuery) ||
            $0.content.lowercased().contains(lowercaseQuery) ||
            $0.tags.contains(where: { $0.lowercased().contains(lowercaseQuery) })
        }
    }

    /// Get recommended articles based on user's recent activity
    func getRecommendedArticles(userProfile: UserProfile, recentSessions: [TrainingSession]) -> [Article] {
        var recommendations: [Article] = []

        // If user is beginner, recommend technique articles
        if userProfile.fitnessLevel == .beginner {
            let techniqueArticles = articles.filter { $0.categoryId == categories.first(where: { $0.name == "Technique" })?.id }
            recommendations.append(contentsOf: techniqueArticles.prefix(3))
        }

        // If user has been doing speed work, recommend recovery articles
        if recentSessions.contains(where: { $0.type == .speedWork }) {
            let recoveryArticles = articles.filter { $0.categoryId == categories.first(where: { $0.name == "Recovery" })?.id }
            recommendations.append(contentsOf: recoveryArticles.prefix(2))
        }

        // Add some featured articles
        recommendations.append(contentsOf: featuredArticles.prefix(2))

        return Array(Set(recommendations)).prefix(6).map { $0 }
    }

    /// Get articles by difficulty level
    func articlesForDifficulty(_ difficulty: Article.Difficulty) -> [Article] {
        return articles.filter { $0.difficulty == difficulty }
    }

    /// Get trending articles (most recently published)
    func getTrendingArticles() -> [Article] {
        return articles
            .sorted(by: { $0.publishedDate > $1.publishedDate })
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Content Management

    /// Add custom article (for premium users)
    func addCustomArticle(_ article: Article) {
        articles.append(article)
        saveArticlesToDocuments()
    }

    /// Update existing article
    func updateArticle(_ article: Article) {
        if let index = articles.firstIndex(where: { $0.id == article.id }) {
            articles[index] = article
            saveArticlesToDocuments()
        }
    }

    /// Delete custom article
    func deleteArticle(_ articleId: UUID) {
        articles.removeAll { $0.id == articleId && $0.isCustom }
        saveArticlesToDocuments()
    }

    /// Save articles to documents directory
    private func saveArticlesToDocuments() {
        let fileURL = documentsDirectory.appendingPathComponent("custom_articles.json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(articles.filter { $0.isCustom })
            try data.write(to: fileURL)
        } catch {
            print("Failed to save articles: \(error.localizedDescription)")
        }
    }

    // MARK: - Data Refresh

    /// Refresh content from server (if available)
    func refreshContent() async {
        isLoading = true
        defer { isLoading = false }

        // In a real app, this would fetch from an API
        // For now, just reload local content
        loadLocalContent()
    }
}

// MARK: - Data Models

/// Article content model
struct Article: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let content: String
    let author: String
    let categoryId: UUID
    let publishedDate: Date
    let lastModified: Date
    let readTime: Int // minutes
    let difficulty: Difficulty
    let tags: [String]
    let imageUrl: String?
    let isFeatured: Bool
    let isPremium: Bool
    let isCustom: Bool

    enum Difficulty: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Article, rhs: Article) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Article category
struct ArticleCategory: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let color: String
    let description: String?
}

/// Response wrapper for article data
struct ArticleResponse: Codable {
    let articles: [Article]
    let lastUpdated: Date
}

// MARK: - Content Templates

class ArticleTemplates {
    static let shared = ArticleTemplates()

    /// Create sample articles for development
    static func createSampleArticles() -> [Article] {
        let techniqueCategory = UUID()

        return [
            Article(
                id: UUID(),
                title: "Perfect Sprinting Technique",
                subtitle: "Master the fundamentals of proper sprint form",
                content: "Proper sprinting technique is essential for both performance and injury prevention...",
                author: "Coach Johnson",
                categoryId: techniqueCategory,
                publishedDate: Date(),
                lastModified: Date(),
                readTime: 5,
                difficulty: .beginner,
                tags: ["technique", "form", "fundamentals"],
                imageUrl: "sprint_technique",
                isFeatured: true,
                isPremium: false,
                isCustom: false
            ),
            Article(
                id: UUID(),
                title: "Advanced Acceleration Techniques",
                subtitle: "Take your starts to the next level",
                content: "Acceleration is crucial in sprint events...",
                author: "Dr. Sarah Martinez",
                categoryId: techniqueCategory,
                publishedDate: Date().addingTimeInterval(-86400),
                lastModified: Date().addingTimeInterval(-86400),
                readTime: 8,
                difficulty: .advanced,
                tags: ["acceleration", "starts", "advanced"],
                imageUrl: "acceleration",
                isFeatured: false,
                isPremium: true,
                isCustom: false
            )
        ]
    }
}

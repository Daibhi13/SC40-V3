import Foundation
import Combine
import SwiftUI

// MARK: - News Models

struct SprintNewsArticle: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let source: NewsSource
    let category: String
    let relevanceScore: Double
    
    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: publishedAt) else { return "Unknown" }
        return date.timeAgoDisplay()
    }
    
    var categoryColor: Color {
        switch category.uppercased() {
        case "100M SPRINT", "SPRINT":
            return Color(red: 1.0, green: 0.8, blue: 0.0)
        case "40-YARD DASH", "NFL":
            return Color(red: 0.0, green: 0.8, blue: 1.0)
        case "SPRINT TRAINING", "COACHING":
            return Color(red: 0.8, green: 0.0, blue: 1.0)
        case "TRACK & FIELD":
            return Color(red: 1.0, green: 0.4, blue: 0.0)
        default:
            return Color(red: 1.0, green: 0.8, blue: 0.0)
        }
    }
}

struct NewsSource: Codable {
    let id: String?
    let name: String
}

struct NewsResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [NewsAPIArticle]
}

struct NewsAPIArticle: Codable {
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let source: NewsSource
}

// MARK: - News Service

@MainActor
class NewsService: ObservableObject {
    static let shared = NewsService()
    
    @Published var articles: [SprintNewsArticle] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    
    private let apiKey = NewsAPIConfig.apiKey
    private let baseURL = NewsAPIConfig.baseURL
    private var cancellables = Set<AnyCancellable>()
    private let sprintKeywords = NewsAPIConfig.sprintKeywords
    
    private init() {
        loadCachedNews()
        Task {
            await fetchLatestNews()
        }
    }
    
    // MARK: - Public Methods
    
    func refreshNews() async {
        await fetchLatestNews()
    }
    
    func fetchLatestNews() async {
        isLoading = true
        errorMessage = nil
        
        // Check if API key is configured
        guard apiKey != "YOUR_NEWS_API_KEY_HERE" && !apiKey.isEmpty else {
            // Use mock data for development
            await loadMockData()
            return
        }
        
        do {
            var allArticles: [SprintNewsArticle] = []
            
            // Fetch sprint-related news from multiple keywords
            for keyword in sprintKeywords.prefix(3) { // Limit to avoid rate limiting
                let articles = try await fetchNewsForKeyword(keyword)
                allArticles.append(contentsOf: articles)
            }
            
            // Remove duplicates and sort by relevance and date
            let uniqueArticles = removeDuplicates(from: allArticles)
            let filteredArticles = filterSprintRelevant(uniqueArticles)
            let sortedArticles = sortByRelevanceAndDate(filteredArticles)
            
            self.articles = Array(sortedArticles.prefix(NewsAPIConfig.maxDisplayArticles))
            self.lastUpdated = Date()
            self.cacheNews()
            
        } catch {
            self.errorMessage = "Failed to fetch news: \(error.localizedDescription)"
            print("❌ News fetch error: \(error)")
            
            // Fallback to mock data on error
            await loadMockData()
        }
        
        isLoading = false
    }
    
    private func loadMockData() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        self.articles = NewsAPIConfig.mockArticles.map { mockArticle in
            SprintNewsArticle(
                id: UUID(),
                title: mockArticle.title,
                description: mockArticle.description,
                url: mockArticle.url,
                urlToImage: nil,
                publishedAt: ISO8601DateFormatter().string(from: mockArticle.publishedAt),
                source: NewsSource(id: nil, name: mockArticle.source),
                category: mockArticle.category.rawValue,
                relevanceScore: 10.0
            )
        }
        
        self.lastUpdated = Date()
        self.errorMessage = nil
        print("📰 Using mock news data for development")
    }
    
    // MARK: - Private Methods
    
    private func fetchNewsForKeyword(_ keyword: String) async throws -> [SprintNewsArticle] {
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        let urlString = "\(baseURL)/everything?q=\(encodedKeyword)&language=en&sortBy=publishedAt&pageSize=50&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw NewsError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NewsError.invalidResponse
        }
        
        let newsResponse = try JSONDecoder().decode(NewsResponse.self, from: data)
        
        return newsResponse.articles.compactMap { apiArticle in
            convertToNewsArticle(apiArticle, keyword: keyword)
        }
    }
    
    private func convertToNewsArticle(_ apiArticle: NewsAPIArticle, keyword: String) -> SprintNewsArticle? {
        guard let description = apiArticle.description,
              !description.isEmpty,
              !apiArticle.title.isEmpty else { return nil }
        
        let category = categorizeArticle(title: apiArticle.title, description: description)
        let relevanceScore = calculateRelevanceScore(title: apiArticle.title, description: description)
        
        return SprintNewsArticle(
            id: UUID(),
            title: apiArticle.title,
            description: description,
            url: apiArticle.url,
            urlToImage: apiArticle.urlToImage,
            publishedAt: apiArticle.publishedAt,
            source: apiArticle.source,
            category: category,
            relevanceScore: relevanceScore
        )
    }
    
    private func categorizeArticle(title: String, description: String) -> String {
        let content = (title + " " + description).lowercased()
        
        if content.contains("40") && (content.contains("yard") || content.contains("dash")) {
            return "40-YARD DASH"
        } else if content.contains("100m") || content.contains("100 meter") {
            return "100M SPRINT"
        } else if content.contains("training") || content.contains("coach") || content.contains("technique") {
            return "SPRINT TRAINING"
        } else if content.contains("nfl") || content.contains("combine") {
            return "NFL COMBINE"
        } else if content.contains("world") && content.contains("athletics") {
            return "WORLD ATHLETICS"
        } else if content.contains("olympic") {
            return "OLYMPICS"
        } else {
            return "SPRINT"
        }
    }
    
    private func calculateRelevanceScore(title: String, description: String) -> Double {
        let content = (title + " " + description).lowercased()
        var score = 0.0
        
        // High relevance keywords
        let highRelevanceKeywords = ["40-yard", "sprint", "100m", "dash", "track and field"]
        for keyword in highRelevanceKeywords {
            if content.contains(keyword) {
                score += 10.0
            }
        }
        
        // Medium relevance keywords
        let mediumRelevanceKeywords = ["athletics", "running", "speed", "fastest", "record"]
        for keyword in mediumRelevanceKeywords {
            if content.contains(keyword) {
                score += 5.0
            }
        }
        
        // Bonus for recent articles
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: ""), // Would use actual publishedAt
           Date().timeIntervalSince(date) < 86400 { // Less than 24 hours
            score += 5.0
        }
        
        return score
    }
    
    private func filterSprintRelevant(_ articles: [SprintNewsArticle]) -> [SprintNewsArticle] {
        return articles.filter { article in
            article.relevanceScore > 5.0 // Only include articles with decent relevance
        }
    }
    
    private func sortByRelevanceAndDate(_ articles: [SprintNewsArticle]) -> [SprintNewsArticle] {
        return articles.sorted { first, second in
            // First sort by relevance score
            if first.relevanceScore != second.relevanceScore {
                return first.relevanceScore > second.relevanceScore
            }
            
            // Then by date (newer first)
            let formatter = ISO8601DateFormatter()
            let firstDate = formatter.date(from: first.publishedAt) ?? Date.distantPast
            let secondDate = formatter.date(from: second.publishedAt) ?? Date.distantPast
            return firstDate > secondDate
        }
    }
    
    private func removeDuplicates(from articles: [SprintNewsArticle]) -> [SprintNewsArticle] {
        var seen = Set<String>()
        return articles.filter { article in
            let key = article.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return seen.insert(key).inserted
        }
    }
    
    // MARK: - Caching
    
    private func cacheNews() {
        do {
            let data = try JSONEncoder().encode(articles)
            UserDefaults.standard.set(data, forKey: "CachedSprintNews")
            UserDefaults.standard.set(Date(), forKey: "NewsLastCached")
        } catch {
            print("❌ Failed to cache news: \(error)")
        }
    }
    
    private func loadCachedNews() {
        guard let data = UserDefaults.standard.data(forKey: "CachedSprintNews"),
              let cachedArticles = try? JSONDecoder().decode([SprintNewsArticle].self, from: data),
              let lastCached = UserDefaults.standard.object(forKey: "NewsLastCached") as? Date else {
            return
        }
        
        // Use cached news if less than 1 hour old
        if Date().timeIntervalSince(lastCached) < 3600 {
            self.articles = cachedArticles
            self.lastUpdated = lastCached
        }
    }
}

// MARK: - News Errors

enum NewsError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid news URL"
        case .invalidResponse:
            return "Invalid response from news service"
        case .decodingError:
            return "Failed to decode news data"
        case .noData:
            return "No news data available"
        }
    }
}

// MARK: - Date Extensions

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

// MARK: - Color Extension

extension Color {
    init(red: Double, green: Double, blue: Double) {
        self.init(red: red, green: green, blue: blue, opacity: 1.0)
    }
}

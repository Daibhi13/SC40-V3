import Foundation
import Combine

// MARK: - Article Model
struct Article: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let author: String
    let publishedDate: Date
    let category: ArticleCategory
    let readTime: Int // minutes
    let imageURL: String?
    let tags: [String]
    
    enum ArticleCategory: String, Codable {
        case training, nutrition, recovery, technique, motivation, news
    }
}

// MARK: - Article Manager
class ArticleManager: ObservableObject {
    @Published var articles: [Article] = []
    @Published var featuredArticles: [Article] = []
    @Published var isLoading = false
    @Published var lastError: String?
    
    func loadArticles() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.articles = self.generateMockArticles()
            self.featuredArticles = Array(self.articles.prefix(3))
            self.isLoading = false
        }
    }
    
    func loadArticles(for category: Article.ArticleCategory) {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.articles = self.generateMockArticles().filter { $0.category == category }
            self.isLoading = false
        }
    }
    
    func searchArticles(query: String) {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.articles = self.generateMockArticles().filter {
                $0.title.lowercased().contains(query.lowercased()) ||
                $0.content.lowercased().contains(query.lowercased()) ||
                $0.tags.contains { $0.lowercased().contains(query.lowercased()) }
            }
            self.isLoading = false
        }
    }
    
    private func generateMockArticles() -> [Article] {
        return [
            Article(
                id: UUID(),
                title: "The Science of Sprint Training",
                content: "Sprint training is a high-intensity form of exercise that can significantly improve your speed, power, and overall athletic performance. Understanding the science behind sprint training can help you optimize your workouts and achieve better results.",
                author: "Dr. Sarah Johnson",
                publishedDate: Date().addingTimeInterval(-86400 * 2),
                category: .training,
                readTime: 5,
                imageURL: nil,
                tags: ["sprint", "training", "science", "performance"]
            ),
            Article(
                id: UUID(),
                title: "Nutrition for Sprinters: Fueling Your Speed",
                content: "Proper nutrition is crucial for sprint performance. Learn what to eat before, during, and after your sprint sessions to maximize your energy and recovery.",
                author: "Mike Chen, RD",
                publishedDate: Date().addingTimeInterval(-86400),
                category: .nutrition,
                readTime: 7,
                imageURL: nil,
                tags: ["nutrition", "fuel", "recovery", "energy"]
            ),
            Article(
                id: UUID(),
                title: "Recovery Techniques for Elite Sprinters",
                content: "Recovery is just as important as training. Discover advanced recovery techniques used by elite sprinters to bounce back faster and perform at their best.",
                author: "Coach Alex Rodriguez",
                publishedDate: Date(),
                category: .recovery,
                readTime: 6,
                imageURL: nil,
                tags: ["recovery", "techniques", "elite", "performance"]
            )
        ]
    }
}

// MARK: - Article View Model
class ArticleViewModel: ObservableObject {
    @Published var selectedArticle: Article?
    @Published var isBookmarked = false
    
    func bookmarkArticle(_ article: Article) {
        // Handle bookmarking
        isBookmarked.toggle()
    }
    
    func shareArticle(_ article: Article) {
        // Handle sharing
    }
}

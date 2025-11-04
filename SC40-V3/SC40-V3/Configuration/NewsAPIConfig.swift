import Foundation

// MARK: - News API Configuration

struct NewsAPIConfig {
    // IMPORTANT: Replace with your actual NewsAPI key from https://newsapi.org/
    static let apiKey = "YOUR_NEWS_API_KEY_HERE"
    
    // News API endpoints
    static let baseURL = "https://newsapi.org/v2"
    static let everythingEndpoint = "/everything"
    static let topHeadlinesEndpoint = "/top-headlines"
    
    // Sprint-specific search terms for maximum relevance
    static let sprintKeywords = [
        "sprint OR sprinting",
        "\"40-yard dash\" OR \"40 yard dash\"",
        "\"100m sprint\" OR \"100 meter sprint\"",
        "\"track and field\" OR athletics",
        "\"NFL combine\" OR \"NFL draft\"",
        "\"world athletics\" OR \"world championships\"",
        "\"olympic sprinting\" OR \"olympic athletics\"",
        "\"fastest man\" OR \"speed record\"",
        "\"sprint training\" OR \"sprint coaching\"",
        "usain bolt OR christian coleman OR noah lyles"
    ]
    
    // Trusted sports news sources
    static let preferredSources = [
        "espn",
        "bbc-sport", 
        "the-sport-bible",
        "fox-sports",
        "bleacher-report",
        "cnn",
        "associated-press",
        "reuters",
        "abc-news",
        "nbc-news"
    ]
    
    // Content filtering settings
    static let maxArticlesPerRequest = 50
    static let maxDisplayArticles = 20
    static let minimumRelevanceScore = 5.0
    static let cacheExpirationHours = 1
    
    // Rate limiting
    static let requestsPerHour = 1000 // NewsAPI free tier limit
    static let requestsPerDay = 1000
    
    // Content categories for sprint news
    enum NewsCategory: String, CaseIterable {
        case sprint = "SPRINT"
        case fortyYardDash = "40-YARD DASH"
        case hundredMeter = "100M SPRINT"
        case sprintTraining = "SPRINT TRAINING"
        case nflCombine = "NFL COMBINE"
        case worldAthletics = "WORLD ATHLETICS"
        case olympics = "OLYMPICS"
        case trackAndField = "TRACK & FIELD"
        
        var displayName: String {
            return self.rawValue
        }
        
        var searchTerms: [String] {
            switch self {
            case .sprint:
                return ["sprint", "sprinting", "sprinter"]
            case .fortyYardDash:
                return ["40-yard", "40 yard", "forty yard", "40yd"]
            case .hundredMeter:
                return ["100m", "100 meter", "100-meter"]
            case .sprintTraining:
                return ["sprint training", "sprint coaching", "speed training"]
            case .nflCombine:
                return ["NFL combine", "NFL draft", "combine results"]
            case .worldAthletics:
                return ["world athletics", "world championships", "diamond league"]
            case .olympics:
                return ["olympic", "olympics", "olympic games"]
            case .trackAndField:
                return ["track and field", "athletics", "track & field"]
            }
        }
        
        var color: (red: Double, green: Double, blue: Double) {
            switch self {
            case .sprint:
                return (1.0, 0.8, 0.0)
            case .fortyYardDash:
                return (0.0, 0.8, 1.0)
            case .hundredMeter:
                return (1.0, 0.4, 0.0)
            case .sprintTraining:
                return (0.8, 0.0, 1.0)
            case .nflCombine:
                return (0.0, 1.0, 0.4)
            case .worldAthletics:
                return (1.0, 0.0, 0.4)
            case .olympics:
                return (0.4, 0.8, 1.0)
            case .trackAndField:
                return (1.0, 0.6, 0.0)
            }
        }
    }
}

// MARK: - News API Setup Instructions

/*
 SETUP INSTRUCTIONS:
 
 1. Get a free API key from NewsAPI:
    - Visit https://newsapi.org/
    - Sign up for a free account
    - Get your API key from the dashboard
    
 2. Replace the API key:
    - Update NewsAPIConfig.apiKey with your actual key
    - Never commit your real API key to version control
    
 3. API Limits (Free Tier):
    - 1,000 requests per day
    - 500 requests per month for development
    - Rate limit: 1000 requests per hour
    
 4. For Production:
    - Consider upgrading to paid plan for higher limits
    - Implement proper error handling and retry logic
    - Add request caching to minimize API calls
    
 5. Alternative News Sources:
    - Guardian API (free tier available)
    - New York Times API (free tier available)
    - Reddit API for community discussions
    - RSS feeds from major sports sites
 */

// MARK: - Mock Data for Development

extension NewsAPIConfig {
    static let mockArticles = [
        MockNewsArticle(
            title: "World Athletics Championships: Sprint Stars Shine in 100m Finals",
            description: "The world's fastest athletes competed in thrilling 100m finals, with new records set in multiple categories.",
            url: "https://example.com/article1",
            source: "World Athletics",
            category: .hundredMeter,
            publishedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
        ),
        MockNewsArticle(
            title: "NFL Combine 2025: Top 40-Yard Dash Performances",
            description: "This year's NFL Combine saw exceptional speed, with multiple prospects running sub-4.4 second 40-yard dashes.",
            url: "https://example.com/article2",
            source: "NFL.com",
            category: .fortyYardDash,
            publishedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ),
        MockNewsArticle(
            title: "Training Tips: How Elite Sprinters Improve Their Start",
            description: "Professional coaches share insights on block starts, reaction time, and acceleration techniques used by world-class sprinters.",
            url: "https://example.com/article3",
            source: "Track & Field News",
            category: .sprintTraining,
            publishedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        )
    ]
}

struct MockNewsArticle {
    let title: String
    let description: String
    let url: String
    let source: String
    let category: NewsAPIConfig.NewsCategory
    let publishedAt: Date
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }
}

import SwiftUI
import SafariServices
import Combine

// Mock NewsService for demo purposes
class NewsService: ObservableObject {
    static let shared = NewsService()
    
    @Published var articles: [SprintNewsArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated = Date()
    
    private init() {}
    
    func refreshNews() async {
        isLoading = true
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.articles = [
                SprintNewsArticle(id: UUID(), title: "New World Record in 40-Yard Dash", description: "Athlete breaks record with incredible speed.", url: "https://example.com", category: "Records", categoryColor: .red, source: NewsSource(name: "Sprint News", logo: "🏃‍♂️"), timeAgo: "2 hours ago"),
                SprintNewsArticle(id: UUID(), title: "Training Tips for Faster Sprints", description: "Expert advice on improving your sprint technique.", url: "https://example.com", category: "Training", categoryColor: .blue, source: NewsSource(name: "Coach Hub", logo: "💡"), timeAgo: "4 hours ago")
            ]
            self.isLoading = false
            self.lastUpdated = Date()
        }
    }
}

// Mock SprintNewsArticle
struct SprintNewsArticle: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let url: String
    let category: String
    let categoryColor: Color
    let source: NewsSource
    let timeAgo: String
}

// Mock NewsSource
struct NewsSource {
    let name: String
    let logo: String
}

struct SprintNewsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var newsService = NewsService.shared
    @State private var showContent = false
    @State private var selectedArticle: SprintNewsArticle?
    @State private var showSafariView = false
    
    var body: some View {
        ZStack {
            // Premium gradient background matching the image
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
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header with news icon
                        VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "newspaper.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        }
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3), value: showContent)
                        
                        VStack(spacing: 8) {
                            Text("Sprint News")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("Global Sprint News")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Text("Updated \(RelativeDateTimeFormatter().localizedString(for: newsService.lastUpdated, relativeTo: Date()))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).delay(0.5), value: showContent)
                    }
                    .padding(.top, 40)
                    
                    // Refresh News Button
                    Button(action: {
                        HapticManager.shared.medium()
                        Task {
                            await newsService.refreshNews()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: newsService.isLoading ? "arrow.clockwise" : "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                                .rotationEffect(.degrees(newsService.isLoading ? 360 : 0))
                                .animation(newsService.isLoading ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: newsService.isLoading)
                            
                            Text(newsService.isLoading ? "Loading..." : "Refresh News")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .frame(height: 44)
                        .padding(.horizontal, 24)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.8, blue: 0.0),
                                    Color(red: 1.0, green: 0.6, blue: 0.0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(22)
                        .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(newsService.isLoading)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8).delay(0.7), value: showContent)
                    
                    // Error Message
                    if let errorMessage = newsService.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Loading State
                    if newsService.isLoading && newsService.articles.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Fetching latest sprint news...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.vertical, 40)
                    }
                    
                    // News Articles
                    if !newsService.articles.isEmpty {
                        VStack(spacing: 16) {
                            ForEach(Array(newsService.articles.enumerated()), id: \.element.id) { index, article in
                                SprintNewsArticleCard(article: article) {
                                    selectedArticle = article
                                    showSafariView = true
                                }
                                .opacity(showContent ? 1 : 0)
                                .animation(.easeInOut(duration: 0.8).delay(0.9 + Double(index) * 0.1), value: showContent)
                            }
                        }
                    }
                    
                    // Empty State
                    if newsService.articles.isEmpty && !newsService.isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "newspaper")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("No sprint news available")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Tap refresh to load the latest news")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.vertical, 40)
                    }
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("Sprint Coach 40")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Stay updated with the latest sprint news")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Powered by NewsAPI • \(newsService.articles.count) articles")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8).delay(2.5), value: showContent)
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                }
        }
        .onAppear {
            showContent = true
            Task {
                await newsService.refreshNews()
            }
        }
        .sheet(isPresented: $showSafariView) {
            if let article = selectedArticle, let url = URL(string: article.url) {
                SafariView(url: url)
            }
        }
    }
}

// MARK: - News Article Card

struct SprintNewsArticleCard: View {
    let article: SprintNewsArticle
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.light()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Category Badge
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text(article.category)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(article.categoryColor)
                    .cornerRadius(12)
                    
                    Spacer()
                }
                
                // Article Content
                VStack(alignment: .leading, spacing: 12) {
                    Text(article.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    
                    Text(article.description)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                
                // Article Footer
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(article.categoryColor)
                        
                        Text(article.source.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(article.categoryColor)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(article.timeAgo)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Read Full Article Button
                HStack {
                    Text("Read full article")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(article.categoryColor)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(article.categoryColor)
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0.15), location: 0.0),
                                .init(color: Color.white.opacity(0.08), location: 1.0)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Safari View

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safari = SFSafariViewController(url: url)
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Preview

struct SprintNewsView_Previews: PreviewProvider {
    static var previews: some View {
        SprintNewsView()
    }
}
}

import Foundation

// Simple LeaderboardEntry for this service
struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let name: String
    let score: Double
    let rank: Int
}

class LeaderboardService: @unchecked Sendable {
    static let shared = LeaderboardService()
    private let leaderboardURL = URL(string: "https://your-api-url.com/leaderboard")!

    func fetchLeaderboard(completion: @escaping @Sendable (Result<[LeaderboardEntry], Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: leaderboardURL) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "LeaderboardService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            do {
                let entries = try JSONDecoder().decode([LeaderboardEntry].self, from: data)
                completion(.success(entries))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

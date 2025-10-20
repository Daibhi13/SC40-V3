import Foundation
import Combine

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

@MainActor
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    #if canImport(FirebaseFirestore)
    private let db = Firestore.firestore()
    #endif
    
    #if canImport(FirebaseAuth)
    private let auth = Auth.auth()
    #endif
    
    @Published var isConfigured = false
    
    private init() {
        configureFirebase()
    }
    
    private func configureFirebase() {
        #if canImport(FirebaseCore)
        guard FirebaseApp.app() == nil else {
            isConfigured = true
            return
        }
        
        FirebaseApp.configure()
        isConfigured = true
        print("🔥 Firebase configured successfully")
        #else
        print("⚠️ Firebase SDK not available - using mock implementation")
        isConfigured = false
        #endif
    }
    
    // MARK: - User Management
    func createUser(with authUser: AuthUser) async throws {
        #if canImport(FirebaseFirestore)
        let userData: [String: Any] = [
            "id": authUser.id,
            "name": authUser.name,
            "email": authUser.email ?? "",
            "profileImageURL": authUser.profileImageURL ?? "",
            "provider": authUser.provider.displayName,
            "createdAt": Timestamp(),
            "lastLoginAt": Timestamp()
        ]
        
        try await db.collection("users").document(authUser.id).setData(userData, merge: true)
        print("✅ User saved to Firestore: \(authUser.name)")
        #else
        print("⚠️ Firebase not available - user data saved locally only")
        #endif
    }
    
    func updateUserLastLogin(userId: String) async throws {
        #if canImport(FirebaseFirestore)
        try await db.collection("users").document(userId).updateData([
            "lastLoginAt": Timestamp()
        ])
        #else
        print("⚠️ Firebase not available - login time not updated")
        #endif
    }
    
    func getUser(userId: String) async throws -> [String: Any]? {
        #if canImport(FirebaseFirestore)
        let document = try await db.collection("users").document(userId).getDocument()
        return document.data()
        #else
        print("⚠️ Firebase not available - returning nil user data")
        return nil
        #endif
    }
    
    // MARK: - Session Data
    func saveTrainingSession(_ session: TrainingSession, userId: String) async throws {
        #if canImport(FirebaseFirestore)
        let sessionData: [String: Any] = [
            "userId": userId,
            "type": session.type,
            "focus": session.focus,
            "week": session.week,
            "day": session.day,
            "completedAt": Timestamp(),
            "sprints": session.sprints.map { sprint in
                [
                    "distanceYards": sprint.distanceYards,
                    "reps": sprint.reps,
                    "restMinutes": sprint.restMinutes,
                    "intensity": sprint.intensity
                ]
            }
        ]
        
        try await db.collection("trainingSessions").addDocument(data: sessionData)
        print("✅ Training session saved to Firestore")
        #else
        print("⚠️ Firebase not available - session data saved locally only")
        #endif
    }
    
    func getUserSessions(userId: String) async throws -> [[String: Any]] {
        #if canImport(FirebaseFirestore)
        let querySnapshot = try await db.collection("trainingSessions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "completedAt", descending: true)
            .getDocuments()
        
        return querySnapshot.documents.map { $0.data() }
        #else
        print("⚠️ Firebase not available - returning empty sessions")
        return []
        #endif
    }
    
    // MARK: - Analytics Data
    func savePerformanceData(userId: String, data: [String: Any]) async throws {
        #if canImport(FirebaseFirestore)
        var performanceData = data
        performanceData["userId"] = userId
        performanceData["timestamp"] = Timestamp()
        
        try await db.collection("performanceData").addDocument(data: performanceData)
        print("✅ Performance data saved to Firestore")
        #else
        print("⚠️ Firebase not available - performance data saved locally only")
        #endif
    }
    
    // MARK: - Local Types (when Firebase not available)
    struct AuthUser {
        let id: String
        let name: String
        let email: String?
        let profileImageURL: String?
        let provider: AuthProvider
    }
    
    enum AuthProvider {
        case apple, facebook, google, instagram, email
        
        var displayName: String {
            switch self {
            case .apple: return "Apple"
            case .facebook: return "Facebook"
            case .google: return "Google"
            case .instagram: return "Instagram"
            case .email: return "Email"
            }
        }
    }
    
    struct TrainingSession {
        let type: String
        let focus: String
        let week: Int
        let day: Int
        let sprints: [SprintSet]
    }
    
    struct SprintSet {
        let distanceYards: Int
        let reps: Int
        let restMinutes: Int
        let intensity: String
    }
}

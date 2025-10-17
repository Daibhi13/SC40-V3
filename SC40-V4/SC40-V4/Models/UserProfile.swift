// Stores profile (age, height, PB, etc.)
import Foundation

public struct UserProfile: Codable {
    public var name: String
    public var email: String?
    public var gender: String // Male, Female, Other
    public var age: Int
    public var height: Double
    public var weight: Double? // Optional, if you want to store weight
    public var personalBests: [String: Double]
    public var level: String // e.g. Beginner, Intermediate, Advanced
    public var baselineTime: Double // e.g. 40 yard dash PB
    public var frequency: Int // training days per week
    public var currentWeek: Int // current week in program
    public var currentDay: Int // current day in program
    public var leaderboardOptIn: Bool = true // Privacy: show on leaderboard
    public var photo: Data? // Profile photo as image data
    public var availableEquipment: [String] = [] // User-selected equipment
    
    // Location information for leaderboard
    public var county: String = "" // County/parish information
    public var state: String = "" // State/province information  
    public var country: String = "" // Country information
    public var locationPermissionGranted: Bool = false // Track if user granted location access
    
    // Session storage - using UUIDs to avoid circular dependency issues
    public var sessionIDs: [UUID] = [] // References to sessions
    public var completedSessionIDs: [UUID] = [] // References to completed sessions
    
    // User session preferences and favorites
    public var favoriteSessionTemplateIDs: [Int] = [] // IDs from SessionLibrary they loved
    public var preferredSessionTemplateIDs: [Int] = [] // IDs they want to see more often
    public var dislikedSessionTemplateIDs: [Int] = [] // IDs they want to avoid
    public var manualSessionOverrides: [UUID: Int] = [:] // Manual session selection: sessionID -> templateID
    public var allowRepeatingFavorites: Bool = true // Allow users to repeat workouts they enjoy
    
    public init(name: String, email: String?, gender: String, age: Int, height: Double, 
                weight: Double?, personalBests: [String: Double], level: String, 
                baselineTime: Double, frequency: Int, currentWeek: Int = 1, currentDay: Int = 1,
                leaderboardOptIn: Bool = true, photo: Data? = nil, availableEquipment: [String] = [],
                county: String = "", state: String = "", country: String = "", 
                locationPermissionGranted: Bool = false,
                favoriteSessionTemplateIDs: [Int] = [], preferredSessionTemplateIDs: [Int] = [],
                dislikedSessionTemplateIDs: [Int] = [], allowRepeatingFavorites: Bool = true) {
        self.name = name
        self.email = email
        self.gender = gender
        self.age = age
        self.height = height
        self.weight = weight
        self.personalBests = personalBests
        self.level = level
        self.baselineTime = baselineTime
        self.frequency = frequency
        self.currentWeek = currentWeek
        self.currentDay = currentDay
        self.leaderboardOptIn = leaderboardOptIn
        self.photo = photo
        self.availableEquipment = availableEquipment
        self.county = county
        self.state = state
        self.country = country
        self.locationPermissionGranted = locationPermissionGranted
        self.favoriteSessionTemplateIDs = favoriteSessionTemplateIDs
        self.preferredSessionTemplateIDs = preferredSessionTemplateIDs
        self.dislikedSessionTemplateIDs = dislikedSessionTemplateIDs
        self.allowRepeatingFavorites = allowRepeatingFavorites
    }
}

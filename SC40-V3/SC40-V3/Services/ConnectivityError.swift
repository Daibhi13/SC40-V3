import Foundation

// MARK: - Connectivity Error Types
// Centralized error handling for all connectivity-related operations
enum ConnectivityError: LocalizedError {
    case deltaSync(String)
    case cacheCorruption
    case networkUnavailable
    case timeout
    case authenticationFailed
    case cancelled
    case unknown
    case socialLoginNotConfigured(String)
    case watchNotReachable
    case sessionNotActivated
    case dataCorrupted
    
    var errorDescription: String? {
        switch self {
        case .deltaSync(let message):
            return message
        case .cacheCorruption:
            return "Cache corruption detected"
        case .networkUnavailable:
            return "Network unavailable"
        case .timeout:
            return "Connection timeout"
        case .authenticationFailed:
            return "Authentication failed"
        case .cancelled:
            return "Operation cancelled"
        case .unknown:
            return "Unknown error occurred"
        case .socialLoginNotConfigured(let message):
            return message
        case .watchNotReachable:
            return "Watch not reachable"
        case .sessionNotActivated:
            return "Session not activated"
        case .dataCorrupted:
            return "Data corrupted during transfer"
        }
    }
}

// MARK: - Authentication Error Types
// Specific errors for authentication operations
enum AuthError: LocalizedError {
    case socialLoginNotConfigured(String)
    case authenticationFailed
    case cancelled
    case unknown
    case missingCredentials
    case invalidName
    case invalidEmail
    
    var errorDescription: String? {
        switch self {
        case .socialLoginNotConfigured(let message):
            return message
        case .authenticationFailed:
            return "Authentication failed"
        case .cancelled:
            return "Authentication cancelled"
        case .unknown:
            return "Unknown authentication error"
        case .missingCredentials:
            return "Missing required credentials"
        case .invalidName:
            return "Invalid name provided"
        case .invalidEmail:
            return "Invalid email address"
        }
    }
}

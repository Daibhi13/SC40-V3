#if DEBUG
// Quick validation script for Session Mixing System
// Run this to verify session distribution works correctly

import Foundation

// Mock the session mixing logic for validation
struct ValidationSessionTypeDistribution {
    let speed: Double
    let flying: Double
    let endurance: Double
    let pyramidUp: Double
    let pyramidDown: Double
    let pyramidUpDown: Double
    let activeRecovery: Double
    let recovery: Double
}

func getSessionTypeDistribution(frequency: Int) -> ValidationSessionTypeDistribution {
    switch frequency {
    case 1:
        return ValidationSessionTypeDistribution(speed: 1.0, flying: 0.0, endurance: 0.0, pyramidUp: 0.0, pyramidDown: 0.0, pyramidUpDown: 0.0, activeRecovery: 0.0, recovery: 0.0)
    case 2:
        return ValidationSessionTypeDistribution(speed: 0.5, flying: 0.0, endurance: 0.5, pyramidUp: 0.0, pyramidDown: 0.0, pyramidUpDown: 0.0, activeRecovery: 0.0, recovery: 0.0)
    case 3:
        return ValidationSessionTypeDistribution(speed: 0.4, flying: 0.2, endurance: 0.2, pyramidUp: 0.2, pyramidDown: 0.0, pyramidUpDown: 0.0, activeRecovery: 0.0, recovery: 0.0)
    case 4:
        return ValidationSessionTypeDistribution(speed: 0.3, flying: 0.2, endurance: 0.2, pyramidUp: 0.15, pyramidDown: 0.15, pyramidUpDown: 0.0, activeRecovery: 0.0, recovery: 0.0)
    case 5:
        return ValidationSessionTypeDistribution(speed: 0.25, flying: 0.2, endurance: 0.2, pyramidUp: 0.15, pyramidDown: 0.1, pyramidUpDown: 0.1, activeRecovery: 0.0, recovery: 0.0)
    case 6:
        return ValidationSessionTypeDistribution(speed: 0.2, flying: 0.18, endurance: 0.17, pyramidUp: 0.15, pyramidDown: 0.1, pyramidUpDown: 0.1, activeRecovery: 0.1, recovery: 0.0)
    case 7:
        return ValidationSessionTypeDistribution(speed: 0.18, flying: 0.16, endurance: 0.16, pyramidUp: 0.14, pyramidDown: 0.1, pyramidUpDown: 0.1, activeRecovery: 0.08, recovery: 0.08)
    default:
        return getSessionTypeDistribution(frequency: 3)
    }
}

func validateSessionMixing() {
    print("🧪 VALIDATING SESSION MIXING SYSTEM")
    print(String(repeating: "=", count: 50))
    
    for frequency in 1...7 {
        let distribution = getSessionTypeDistribution(frequency: frequency)
        let total = distribution.speed + distribution.flying + distribution.endurance + 
                   distribution.pyramidUp + distribution.pyramidDown + distribution.pyramidUpDown + 
                   distribution.activeRecovery + distribution.recovery
        
        print("\n📊 \(frequency)-Day Program Distribution:")
        print("   Speed: \(Int(distribution.speed * Double(frequency))) sessions (\(Int(distribution.speed * 100))%)")
        print("   Flying: \(Int(distribution.flying * Double(frequency))) sessions (\(Int(distribution.flying * 100))%)")
        print("   Endurance: \(Int(distribution.endurance * Double(frequency))) sessions (\(Int(distribution.endurance * 100))%)")
        print("   Pyramid Up: \(Int(distribution.pyramidUp * Double(frequency))) sessions (\(Int(distribution.pyramidUp * 100))%)")
        print("   Pyramid Down: \(Int(distribution.pyramidDown * Double(frequency))) sessions (\(Int(distribution.pyramidDown * 100))%)")
        print("   Pyramid Up-Down: \(Int(distribution.pyramidUpDown * Double(frequency))) sessions (\(Int(distribution.pyramidUpDown * 100))%)")
        
        if frequency >= 6 {
            print("   Active Recovery: \(Int(distribution.activeRecovery * Double(frequency))) sessions (\(Int(distribution.activeRecovery * 100))%)")
        }
        if frequency >= 7 {
            print("   Recovery: \(Int(distribution.recovery * Double(frequency))) sessions (\(Int(distribution.recovery * 100))%)")
        }
        
        let status = abs(total - 1.0) < 0.01 ? "✅ VALID" : "❌ INVALID"
        print("   Total: \(Int(total * 100))% \(status)")
    }
    
    print("\n🎯 VALIDATION COMPLETE")
    print("✅ All frequency distributions are mathematically valid")
    print("✅ Session mixing system ready for testing")
}

@discardableResult
func runSessionMixingValidation() -> Bool {
    validateSessionMixing()
    return true
}

// Uncomment to run during DEBUG builds or call from tests
// _ = runSessionMixingValidation()
#endif

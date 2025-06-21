import Foundation

enum VerificationStatus {
    case initial
    case codeSent
    case verified
    
    var buttonText: String {
        switch self {
        case .initial:
            return "Sign Up"
        case .codeSent:
            return "Check Your Verification"
        case .verified:
            return "Continue"
        }
    }
} 

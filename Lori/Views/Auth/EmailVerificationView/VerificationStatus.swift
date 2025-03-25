import Foundation

enum VerificationStatus {
    case initial
    case codeSent
    case verified
    
    var buttonText: String {
        switch self {
        case .initial:
            return "Kayıt Ol"
        case .codeSent:
            return "Doğrulamayı Kontrol Et"
        case .verified:
            return "Devam Et"
        }
    }
} 
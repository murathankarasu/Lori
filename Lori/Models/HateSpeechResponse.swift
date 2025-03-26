import Foundation

struct HateSpeechResponse: Codable {
    let status: String
    let data: HateSpeechData
    let timestamp: String
    
    struct HateSpeechData: Codable {
        let isHateSpeech: Bool
        let confidence: Double
        let category: String
        let details: Details
        
        struct Details: Codable {
            let emojiCount: Int
            let textLength: Int
            let categoryDetails: [String]
            let severityScore: Double
            let metrics: Metrics
            
            struct Metrics: Codable {
                let wordCount: Int
                let averageWordLength: Double
                let punctuationCount: Int
                let capitalizationRatio: Double
            }
            
            enum CodingKeys: String, CodingKey {
                case emojiCount = "emoji_count"
                case textLength = "text_length"
                case categoryDetails = "category_details"
                case severityScore = "severity_score"
                case metrics
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case isHateSpeech = "is_hate_speech"
            case confidence
            case category
            case details
        }
    }
}

enum HateSpeechError: LocalizedError {
    case networkError(Error)
    case serverError(Int)
    case decodingError(DecodingError)
    case connectionError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Ağ hatası: \(error.localizedDescription)"
        case .serverError(let code):
            return "Sunucu hatası: \(code)"
        case .decodingError(let error):
            return "Veri çözümleme hatası: \(error.localizedDescription)"
        case .connectionError:
            return "Bağlantı hatası"
        case .invalidResponse:
            return "Geçersiz sunucu yanıtı"
        }
    }
}

// API Response modelleri
struct APIResponse: Codable {
    let status: String
    let data: ResponseData?
    let timestamp: String
    
    struct ResponseData: Codable {
        let isHateSpeech: Bool
        let confidence: Double
        let category: String
        let categoryDetails: [String]
        let severityScore: Int
        let message: String
        let details: Details
        
        struct Details: Codable {
            let emojiCount: Int
            let textLength: Int
            let foundWords: [String]
        }
        
        enum CodingKeys: String, CodingKey {
            case isHateSpeech = "is_hate_speech"
            case confidence, category
            case categoryDetails = "category_details"
            case severityScore = "severity_score"
            case message, details
        }
    }
}

struct CategoriesResponse: Codable {
    let status: String
    let data: [String: [String]]
    let timestamp: String
}

enum WarningLevel: String {
    case safe = "Güvenli"
    case low = "Düşük Risk"
    case medium = "Orta Risk"
    case high = "Yüksek Risk"
    
    var color: String {
        switch self {
        case .safe: return "green"
        case .low: return "yellow"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
    
    var description: String {
        switch self {
        case .safe:
            return "İçerik güvenli görünüyor."
        case .low:
            return "İçerik düşük risk taşıyor, dikkatli olun."
        case .medium:
            return "İçerik orta düzeyde risk taşıyor, gözden geçirin."
        case .high:
            return "İçerik yüksek risk taşıyor, paylaşılması önerilmez."
        }
    }
} 
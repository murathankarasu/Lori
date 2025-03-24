import Foundation

struct HateSpeechResponse: Codable {
    let isHateSpeech: Bool
    let confidence: Double
    let categories: [String]
    
    enum CodingKeys: String, CodingKey {
        case isHateSpeech = "is_hate_speech"
        case confidence
        case categories
    }
} 
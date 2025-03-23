import Foundation

struct HateSpeechResponse: Codable {
    let is_hate_speech: Bool
    let confidence: Double
    let category: String
} 
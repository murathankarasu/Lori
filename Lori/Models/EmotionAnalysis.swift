import Foundation
import FirebaseFirestore

struct EmotionAnalysis: Codable, Hashable, Equatable {
    let emotion: String
    let confidence: Double
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case emotion
        case confidence
        case timestamp
    }
    
    init(emotion: String, confidence: Double, timestamp: Date = Date()) {
        self.emotion = emotion
        self.confidence = confidence
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        emotion = try container.decode(String.self, forKey: .emotion)
        confidence = try container.decode(Double.self, forKey: .confidence)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(emotion, forKey: .emotion)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    // Hashable ve Equatable için gerekli fonksiyonlar
    static func == (lhs: EmotionAnalysis, rhs: EmotionAnalysis) -> Bool {
        return lhs.emotion == rhs.emotion &&
               lhs.confidence == rhs.confidence &&
               lhs.timestamp == rhs.timestamp
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(emotion)
        hasher.combine(confidence)
        hasher.combine(timestamp)
    }
} 
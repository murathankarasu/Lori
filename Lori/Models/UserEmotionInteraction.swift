import Foundation
import FirebaseFirestore

struct UserEmotionInteraction: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let postId: String
    let interactionType: InteractionType // like, comment, create
    let emotion: String
    let confidence: Double
    let timestamp: Date
    
    enum InteractionType: String, Codable {
        case like
        case comment
        case create
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case postId
        case interactionType
        case emotion
        case confidence
        case timestamp
    }
    
    init(userId: String, postId: String, interactionType: InteractionType, emotion: String, confidence: Double, timestamp: Date = Date()) {
        self.userId = userId
        self.postId = postId
        self.interactionType = interactionType
        self.emotion = emotion
        self.confidence = confidence
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String?.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        postId = try container.decode(String.self, forKey: .postId)
        interactionType = try container.decode(InteractionType.self, forKey: .interactionType)
        emotion = try container.decode(String.self, forKey: .emotion)
        confidence = try container.decode(Double.self, forKey: .confidence)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(postId, forKey: .postId)
        try container.encode(interactionType, forKey: .interactionType)
        try container.encode(emotion, forKey: .emotion)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(timestamp, forKey: .timestamp)
    }
} 
import Foundation

struct DisinformationResponse: Codable {
    let isVerified: Bool
    let sources: [String]?
    let confidence: Double
    let explanation: String
    
    init(isVerified: Bool, sources: [String]?, confidence: Double, explanation: String) {
        self.isVerified = isVerified
        self.sources = sources
        self.confidence = confidence
        self.explanation = explanation
    }
    
    enum CodingKeys: String, CodingKey {
        case isVerified = "is_verified"
        case sources
        case confidence
        case explanation
    }
}

struct DisinformationCheckRequest: Codable {
    let content: String
    let postId: String
    let userId: String
} 
import Foundation

struct Comment: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let content: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case username
        case content
        case timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        username = try container.decode(String.self, forKey: .username)
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(username, forKey: .username)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    init(id: String, userId: String, username: String, content: String, timestamp: Date) {
        self.id = id
        self.userId = userId
        self.username = username
        self.content = content
        self.timestamp = timestamp
    }
} 
import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let postId: String
    let userId: String
    let username: String
    let content: String
    let timestamp: Date
    
    // Static relative time formatter
    var relativeTimeString: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: timestamp, to: now)
        
        if let year = components.year, year >= 1 {
            return "\(year) year\(year == 1 ? "" : "s") ago"
        }
        if let month = components.month, month >= 1 {
            return "\(month) month\(month == 1 ? "" : "s") ago"
        }
        if let week = components.weekOfYear, week >= 1 {
            return "\(week) week\(week == 1 ? "" : "s") ago"
        }
        if let day = components.day, day >= 1 {
            return "\(day) day\(day == 1 ? "" : "s") ago"
        }
        if let hour = components.hour, hour >= 1 {
            return "\(hour) hour\(hour == 1 ? "" : "s") ago"
        }
        if let minute = components.minute, minute >= 1 {
            return "\(minute) minute\(minute == 1 ? "" : "s") ago"
        }
        return "Just now"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId
        case userId
        case username
        case content
        case timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String?.self, forKey: .id)
        postId = try container.decode(String.self, forKey: .postId)
        userId = try container.decode(String.self, forKey: .userId)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? "Anonim"
        content = try container.decode(String.self, forKey: .content)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(postId, forKey: .postId)
        try container.encode(userId, forKey: .userId)
        try container.encode(username, forKey: .username)
        try container.encode(content, forKey: .content)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    init(id: String, postId: String, userId: String, username: String, content: String, timestamp: Date) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.username = username
        self.content = content
        self.timestamp = timestamp
    }
} 

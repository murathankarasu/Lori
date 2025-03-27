import Foundation
import FirebaseFirestore

struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let content: String
    let imageUrl: String?
    let timestamp: Date
    var likes: Int
    var comments: [Comment]
    var isViewed: Bool
    var tags: [String]
    var category: String // "featured" veya "following"
    var mentions: [String] // @kullanıcıadı şeklinde etiketlenen kullanıcılar
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case username
        case content
        case imageUrl
        case timestamp
        case likes
        case comments
        case isViewed
        case tags
        case category
        case mentions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        username = try container.decode(String.self, forKey: .username)
        content = try container.decode(String.self, forKey: .content)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        likes = try container.decode(Int.self, forKey: .likes)
        comments = try container.decode([Comment].self, forKey: .comments)
        isViewed = try container.decode(Bool.self, forKey: .isViewed)
        tags = try container.decode([String].self, forKey: .tags)
        category = try container.decode(String.self, forKey: .category)
        mentions = try container.decode([String].self, forKey: .mentions)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(username, forKey: .username)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(likes, forKey: .likes)
        try container.encode(comments, forKey: .comments)
        try container.encode(isViewed, forKey: .isViewed)
        try container.encode(tags, forKey: .tags)
        try container.encode(category, forKey: .category)
        try container.encode(mentions, forKey: .mentions)
    }
    
    init(id: String, userId: String, username: String, content: String, imageUrl: String?, timestamp: Date, likes: Int, comments: [Comment], isViewed: Bool, tags: [String], category: String = "featured", mentions: [String] = []) {
        self.id = id
        self.userId = userId
        self.username = username
        self.content = content
        self.imageUrl = imageUrl
        self.timestamp = timestamp
        self.likes = likes
        self.comments = comments
        self.isViewed = isViewed
        self.tags = tags
        self.category = category
        self.mentions = mentions
    }
} 
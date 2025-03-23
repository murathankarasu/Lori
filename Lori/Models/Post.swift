import Foundation

struct Post: Identifiable {
    let id: String
    let username: String
    let content: String
    let timestamp: Date
    let likes: Int
    let userId: String
    let tags: [String]
    var isViewed: Bool
    let similarPosts: [String]
    
    init(id: String, username: String, content: String, timestamp: Date, likes: Int = 0, userId: String, tags: [String] = [], isViewed: Bool = false, similarPosts: [String] = []) {
        self.id = id
        self.username = username
        self.content = content
        self.timestamp = timestamp
        self.likes = likes
        self.userId = userId
        self.tags = tags
        self.isViewed = isViewed
        self.similarPosts = similarPosts
    }
} 
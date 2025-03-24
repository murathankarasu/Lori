import Foundation

struct Post: Identifiable {
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
} 
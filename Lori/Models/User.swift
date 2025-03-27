import Foundation

struct User: Identifiable, Codable {
    let id: String
    let username: String
    let email: String
    let profileImageUrl: String?
    let bio: String?
    let followers: Int
    let following: Int
    let createdAt: Date
    let isVerified: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case profileImageUrl
        case bio
        case followers
        case following
        case createdAt
        case isVerified
    }
} 
import Foundation

struct User: Identifiable {
    let id: String
    let username: String
    let email: String
    let bio: String
    let profileImageUrl: String?
    let followers: [String]
    let following: [String]
} 
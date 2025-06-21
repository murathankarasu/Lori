import Foundation
import Firebase
import FirebaseFirestore

struct DirectMessage: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let senderId: String
    let receiverId: String
    let content: String
    let timestamp: Date
    var isRead: Bool
    var imageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case receiverId
        case content
        case timestamp
        case isRead
        case imageURL
    }
    
    static func == (lhs: DirectMessage, rhs: DirectMessage) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct DirectMessageConversation: Identifiable, Codable {
    @DocumentID var id: String?
    let users: [String] // İki kullanıcının ID'leri
    let lastMessage: String
    let lastMessageTimestamp: Date
    let lastMessageSenderId: String
    var lastMessageRead: Bool
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case users
        case lastMessage
        case lastMessageTimestamp
        case lastMessageSenderId
        case lastMessageRead
        case createdAt
    }
} 

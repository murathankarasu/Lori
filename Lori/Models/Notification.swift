import Foundation
import FirebaseFirestore

struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let data: [String: String]? // Additional data like postId, senderId, etc.
    
    enum NotificationType: String, Codable, CaseIterable {
        case like = "like"
        case comment = "comment"
        case follow = "follow"
        case message = "message"
        case system = "system"
        case welcome = "welcome"
        case achievement = "achievement"
    }
    
    init(userId: String, type: NotificationType, title: String, message: String, isRead: Bool = false, data: [String: String]? = nil) {
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = Date()
        self.isRead = isRead
        self.data = data
    }
    
    var iconName: String {
        switch type {
        case .like:
            return "heart.fill"
        case .comment:
            return "bubble.left.fill"
        case .follow:
            return "person.badge.plus.fill"
        case .message:
            return "message.fill"
        case .system:
            return "gear.circle.fill"
        case .welcome:
            return "hand.wave.fill"
        case .achievement:
            return "trophy.fill"
        }
    }
    
    var iconColor: String {
        switch type {
        case .like:
            return "red"
        case .comment:
            return "blue"
        case .follow:
            return "green"
        case .message:
            return "purple"
        case .system:
            return "gray"
        case .welcome:
            return "orange"
        case .achievement:
            return "yellow"
        }
    }
} 
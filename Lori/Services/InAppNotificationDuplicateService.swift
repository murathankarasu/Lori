import Foundation

class InAppNotificationDuplicateService {
    static let shared = InAppNotificationDuplicateService()
    
    private init() {}
    
    // MARK: - Duplicate Prevention
    func generateDuplicateKey(userId: String, type: AppNotification.NotificationType, data: [String: String]?) -> String {
        var key = "\(userId)_\(type.rawValue)"
        
        // Add relevant data to the key based on notification type
        switch type {
        case .like, .comment:
            if let postId = data?["postId"], let senderId = data?["senderId"] {
                key += "_\(postId)_\(senderId)"
            }
        case .follow:
            if let senderId = data?["senderId"] {
                key += "_\(senderId)"
            }
        case .message:
            if let conversationId = data?["conversationId"] {
                key += "_\(conversationId)"
            }
        case .system, .welcome, .achievement:
            if let identifier = data?["identifier"] {
                key += "_\(identifier)"
            }
        }
        
        return key
    }
    
    func shouldCreateNotification(duplicateKey: String, type: AppNotification.NotificationType) -> Bool {
        let lastSentKey = "lastSent_\(duplicateKey)"
        let lastSentTime = UserDefaults.standard.double(forKey: lastSentKey)
        let currentTime = Date().timeIntervalSince1970
        
        // Different time intervals for different notification types
        let cooldownInterval: TimeInterval
        switch type {
        case .like, .comment:
            cooldownInterval = 3600 // 1 hour
        case .follow:
            cooldownInterval = 86400 // 24 hours
        case .message:
            cooldownInterval = 60 // 1 minute (mesajlar daha sık gelebilir)
        case .system, .achievement:
            cooldownInterval = 86400 * 7 // 1 week
        case .welcome:
            cooldownInterval = Double.greatestFiniteMagnitude // Only once
        }
        
        return (currentTime - lastSentTime) > cooldownInterval
    }
    
    func storeDuplicateKey(_ duplicateKey: String) {
        let lastSentKey = "lastSent_\(duplicateKey)"
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastSentKey)
    }
} 
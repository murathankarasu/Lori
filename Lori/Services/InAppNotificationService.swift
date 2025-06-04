import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class InAppNotificationService: ObservableObject {
    static let shared = InAppNotificationService()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    private let coreService = InAppNotificationCoreService.shared
    private let badgeService = InAppNotificationBadgeService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Forward notifications from core service
        coreService.$notifications
            .assign(to: \.notifications, on: self)
            .store(in: &cancellables)
        
        // Forward unread count from badge service
        badgeService.$unreadCount
            .assign(to: \.unreadCount, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Create Notifications
    func createNotification(
        for userId: String,
        type: AppNotification.NotificationType,
        title: String,
        message: String,
        data: [String: String]? = nil
    ) {
        coreService.createNotification(
            for: userId,
            type: type,
            title: title,
            message: message,
            data: data
        )
    }
    
    // MARK: - Mark as Read
    func markAsRead(_ notification: AppNotification) {
        coreService.markAsRead(notification)
    }
    
    func markAllAsRead() {
        coreService.markAllAsRead()
    }
    
    // MARK: - Delete Notifications
    func deleteNotification(_ notification: AppNotification) {
        coreService.deleteNotification(notification)
    }
    
    func deleteAllNotifications() {
        coreService.deleteAllNotifications()
    }
    
    func deleteTestNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Test notification IDs and patterns to identify and delete
        let testIdentifiers = [
            "test_user_id", "another_user_id", "new_follower_id", 
            "message_sender_id", "test_conversation_id", "test_post_id",
            "system_update_v1_2"
        ]
        
        let batch = Firestore.firestore().batch()
        
        for notification in notifications {
            guard let notificationId = notification.id else { continue }
            
            // Check if this is a test notification
            let isTestNotification = testIdentifiers.contains { identifier in
                notification.data?.values.contains(identifier) ?? false
            }
            
            if isTestNotification {
                let documentRef = Firestore.firestore().collection("notifications").document(notificationId)
                batch.deleteDocument(documentRef)
            }
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                print("Error deleting test notifications: \(error.localizedDescription)")
            } else {
                print("Test notifications deleted")
                // Update badge count after deleting test notifications
                DispatchQueue.main.async {
                    self?.badgeService.updateBadgeCount(notifications: self?.notifications ?? [])
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    func getRecentNotifications(limit: Int = 10) -> [AppNotification] {
        return Array(notifications.prefix(limit))
    }
    
    func getUnreadNotifications() -> [AppNotification] {
        return notifications.filter { !$0.isRead }
    }
    
    // MARK: - Convenient Creation Methods
    func createLikeNotification(for userId: String, from senderId: String, senderName: String, postId: String) {
        createNotification(
            for: userId,
            type: .like,
            title: "New Like",
            message: "\(senderName) liked your post ❤️",
            data: ["senderId": senderId, "postId": postId, "senderName": senderName]
        )
    }
    
    func createCommentNotification(for userId: String, from senderId: String, senderName: String, postId: String) {
        createNotification(
            for: userId,
            type: .comment,
            title: "New Comment",
            message: "\(senderName) commented on your post 💬",
            data: ["senderId": senderId, "postId": postId, "senderName": senderName]
        )
    }
    
    func createFollowNotification(for userId: String, from senderId: String, senderName: String) {
        createNotification(
            for: userId,
            type: .follow,
            title: "New Follower",
            message: "\(senderName) started following you 👥",
            data: ["senderId": senderId, "senderName": senderName]
        )
    }
    
    func createWelcomeNotification(for userId: String) {
        createNotification(
            for: userId,
            type: .welcome,
            title: "Welcome! 🎉",
            message: "Welcome to Lorien! Start interacting with the community.",
            data: ["identifier": "welcome"]
        )
    }
    
    // MARK: - Test Functions
    func createTestNotifications(for userId: String) {
        let now = Date()
        
        // Test like notification (2 minutes ago)
        let likeNotification = AppNotification(
            userId: userId,
            type: .like,
            title: "New Like",
            message: "TestUser liked your post ❤️",
            data: ["senderId": "test_user_id", "postId": "test_post_id", "senderName": "TestUser"]
        )
        createNotificationWithCustomTime(likeNotification, timestamp: now.addingTimeInterval(-120)) // 2 min ago
        
        // Test comment notification (5 minutes ago)
        let commentNotification = AppNotification(
            userId: userId,
            type: .comment,
            title: "New Comment",
            message: "AnotherUser commented on your post 💬",
            data: ["senderId": "another_user_id", "postId": "test_post_id", "senderName": "AnotherUser"]
        )
        createNotificationWithCustomTime(commentNotification, timestamp: now.addingTimeInterval(-300)) // 5 min ago
        
        // Test follow notification (1 hour ago)
        let followNotification = AppNotification(
            userId: userId,
            type: .follow,
            title: "New Follower",
            message: "NewFollower started following you 👥",
            data: ["senderId": "new_follower_id", "senderName": "NewFollower"]
        )
        createNotificationWithCustomTime(followNotification, timestamp: now.addingTimeInterval(-3600)) // 1 hour ago
        
        // Test message notification (30 seconds ago)
        let messageNotification = AppNotification(
            userId: userId,
            type: .message,
            title: "MessageSender",
            message: "Hello! How are you? This is a sample long message...",
            data: ["senderId": "message_sender_id", "conversationId": "test_conversation_id", "senderName": "MessageSender"]
        )
        createNotificationWithCustomTime(messageNotification, timestamp: now.addingTimeInterval(-30)) // 30 sec ago
        
        // Test system notification (1 day ago)
        let systemNotification = AppNotification(
            userId: userId,
            type: .system,
            title: "System Update",
            message: "Lorien has been updated with new features! 🚀",
            data: ["identifier": "system_update_v1_2"]
        )
        createNotificationWithCustomTime(systemNotification, timestamp: now.addingTimeInterval(-86400)) // 1 day ago
    }
    
    private func createNotificationWithCustomTime(_ notification: AppNotification, timestamp: Date) {
        // Create a dictionary manually to control the timestamp
        let notificationData: [String: Any] = [
            "userId": notification.userId,
            "type": notification.type.rawValue,
            "title": notification.title,
            "message": notification.message,
            "timestamp": Timestamp(date: timestamp),
            "isRead": notification.isRead,
            "data": notification.data ?? [:]
        ]
        
        Firestore.firestore().collection("notifications").addDocument(data: notificationData) { error in
            if let error = error {
                print("Error creating test notification: \(error.localizedDescription)")
            } else {
                print("Test notification created successfully with custom timestamp")
            }
        }
    }
} 
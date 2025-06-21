import Foundation
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import UIKit

class NotificationCoreService: ObservableObject {
    static let shared = NotificationCoreService()
    
    private let db = Firestore.firestore()
    private let inAppNotificationService = InAppNotificationService.shared
    private let settingsService = NotificationSettingsService.shared
    private var notificationListeners: [ListenerRegistration] = []
    
    // Track last app open time
    private var lastAppOpenTime: Date {
        get {
            if let timestamp = UserDefaults.standard.object(forKey: "lastAppOpenTime") as? Date {
                return timestamp
            }
            return Date()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastAppOpenTime")
        }
    }
    
    init() {
        lastAppOpenTime = Date()
        setupMessageNotificationListener()
    }
    
    deinit {
        removeAllListeners()
    }
    
    // MARK: - App Lifecycle
    func applicationWillEnterForeground() {
        lastAppOpenTime = Date()
    }
    
    // MARK: - Message Notifications
    private func setupMessageNotificationListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let listener = db.collection("conversations")
            .whereField("users", arrayContains: userId)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Message listener error: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else { return }
                
                for document in documents {
                    let conversationId = document.documentID
                    self.setupMessageListener(for: conversationId, userId: userId)
                }
            }
        
        notificationListeners.append(listener)
    }
    
    private func setupMessageListener(for conversationId: String, userId: String) {
        let listener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Message listener error: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documentChanges else { return }
                
                for change in documents {
                    if change.type == .added {
                        let messageData = change.document.data()
                        let senderId = messageData["senderId"] as? String ?? ""
                        
                        if let timestamp = messageData["timestamp"] as? Timestamp {
                            let messageDate = timestamp.dateValue()
                            
                            if senderId != userId && messageDate > self.lastAppOpenTime {
                                self.sendMessageNotification(messageData: messageData, conversationId: conversationId, recipientId: userId)
                            }
                        }
                    }
                }
            }
        
        notificationListeners.append(listener)
    }
    
    private func sendMessageNotification(messageData: [String: Any], conversationId: String, recipientId: String) {
        guard settingsService.notificationSettings.messageNotifications,
              let senderId = messageData["senderId"] as? String,
              let text = messageData["content"] as? String else { return }
        
        db.collection("users").document(senderId).getDocument { [weak self] document, error in
            guard let self = self,
                  let document = document,
                  document.exists,
                  let userData = document.data() else { return }
            
            let senderName = userData["username"] as? String ?? "Unknown User"
            
            DispatchQueue.main.async {
                self.scheduleMessageNotification(
                    title: senderName,
                    body: text,
                    conversationId: conversationId,
                    senderId: senderId
                )
                
                // Create in-app notification for the recipient (not the sender)
                let shortMessage = text.count > 50 ? 
                    String(text.prefix(50)) + "..." : 
                    text
                
                self.inAppNotificationService.createNotification(
                    for: recipientId,
                    type: .message,
                    title: senderName,
                    message: shortMessage,
                    data: [
                        "senderId": senderId,
                        "conversationId": conversationId,
                        "senderName": senderName
                    ]
                )
            }
        }
    }
    
    private func scheduleMessageNotification(title: String, body: String, conversationId: String, senderId: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        content.userInfo = [
            "type": "message",
            "conversationId": conversationId,
            "senderId": senderId
        ]
        
        let request = UNNotificationRequest(
            identifier: "message_\(conversationId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling message notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Retention Notifications
    func scheduleRetentionNotifications() {
        guard settingsService.notificationSettings.retentionNotifications else { return }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: getRetentionNotificationIds())
        
        let retentionMessages = [
            (hours: 24, message: "You have new messages from your friends! 💬"),
            (hours: 72, message: "We miss you! New posts are waiting 📸"),
            (hours: 168, message: "See what you missed this week! 🌟"),
            (hours: 336, message: "Long time no see. Your community is waiting! 👥")
        ]
        
        for (index, retention) in retentionMessages.enumerated() {
            scheduleRetentionNotification(
                hours: retention.hours,
                message: retention.message,
                identifier: "retention_\(index)"
            )
        }
    }
    
    private func scheduleRetentionNotification(hours: Int, message: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "Lorien"
        content.body = message
        content.sound = .default
        content.userInfo = ["type": "retention"]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(hours * 3600),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling retention notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func getRetentionNotificationIds() -> [String] {
        return (0...3).map { "retention_\($0)" }
    }
    
    // MARK: - Cleanup
    private func removeAllListeners() {
        for listener in notificationListeners {
            listener.remove()
        }
        notificationListeners.removeAll()
    }
    
    // MARK: - Badge Management
    func updateBadgeCount() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        var totalUnreadCount = 0
        
        // Count unread messages
        let group = DispatchGroup()
        
        group.enter()
        db.collection("conversations")
            .whereField("users", arrayContains: userId)
            .getDocuments { [weak self] querySnapshot, error in
                defer { group.leave() }
                
                guard let self = self,
                      let documents = querySnapshot?.documents else { return }
                
                for document in documents {
                    let conversationId = document.documentID
                    
                    group.enter()
                    self.db.collection("conversations")
                        .document(conversationId)
                        .collection("messages")
                        .whereField("isRead", isEqualTo: false)
                        .whereField("senderId", isNotEqualTo: userId)
                        .getDocuments { querySnapshot, error in
                            defer { group.leave() }
                            
                            if let count = querySnapshot?.documents.count {
                                totalUnreadCount += count
                            }
                        }
                }
            }
        
        group.notify(queue: .main) {
            UIApplication.shared.applicationIconBadgeNumber = totalUnreadCount
        }
    }
    
    // MARK: - Social Notifications
    func sendSocialNotification(type: SocialNotificationType, from senderId: String, to receiverId: String? = nil, postId: String? = nil) {
        // receiverId should always be provided - if not, don't send notification
        guard let targetUserId = receiverId else {
            print("❌ Error: receiverId is required for social notifications")
            return
        }
        
        // Don't send notification to self
        guard senderId != targetUserId else { 
            print("🔔 DEBUG: Not sending social notification - sender and receiver are the same")
            print("   - Sender ID: \(senderId)")
            print("   - Target ID: \(targetUserId)")
            return 
        }
        
        print("🔔 DEBUG: Processing social notification")
        print("   - Type: \(type.rawValue)")
        print("   - From: \(senderId)")
        print("   - To: \(targetUserId)")
        print("   - Post ID: \(postId ?? "None")")
        
        // Get sender's information
        db.collection("users").document(senderId).getDocument { [weak self] document, error in
            guard let self = self,
                  let document = document,
                  document.exists,
                  let userData = document.data() else { 
                print("❌ Error: Could not get sender user data")
                return 
            }
            
            let senderName = userData["username"] as? String ?? "Unknown User"
            print("   - Sender name: \(senderName)")
            
            var shouldSend = false
            var title = ""
            var body = ""
            
            switch type {
            case .like:
                shouldSend = self.settingsService.notificationSettings.likeNotifications
                title = "New Like"
                body = "\(senderName) liked your post ❤️"
            case .comment:
                shouldSend = self.settingsService.notificationSettings.commentNotifications
                title = "New Comment"
                body = "\(senderName) commented on your post 💬"
            case .follow:
                shouldSend = self.settingsService.notificationSettings.followNotifications
                title = "New Follower"
                body = "\(senderName) started following you 👥"
            }
            
            print("   - Should send: \(shouldSend)")
            
            if shouldSend {
                DispatchQueue.main.async {
                    print("📤 Sending push notification to user: \(targetUserId)")
                    self.scheduleSocialNotification(
                        title: title,
                        body: body,
                        type: type,
                        senderId: senderId,
                        postId: postId,
                        receiverId: targetUserId
                    )
                }
            }
        }
    }
    
    private func scheduleSocialNotification(title: String, body: String, type: SocialNotificationType, senderId: String, postId: String?, receiverId: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        var userInfo: [String: Any] = [
            "type": "social",
            "socialType": type.rawValue,
            "senderId": senderId,
            "receiverId": receiverId
        ]
        
        if let postId = postId {
            userInfo["postId"] = postId
        }
        
        content.userInfo = userInfo
        
        let request = UNNotificationRequest(
            identifier: "social_\(type.rawValue)_\(senderId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling social notification: \(error.localizedDescription)")
            }
        }
    }
} 
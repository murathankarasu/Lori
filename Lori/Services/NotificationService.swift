import Foundation
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import UIKit

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    private let db = Firestore.firestore()
    private var notificationListeners: [ListenerRegistration] = []
    
    @Published var isNotificationsEnabled = false
    @Published var notificationSettings: NotificationSettings = NotificationSettings()
    
    override init() {
        super.init()
        setupNotifications()
        loadNotificationSettings()
    }
    
    deinit {
        removeAllListeners()
    }
    
    // MARK: - Setup
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
    }
    
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isNotificationsEnabled = granted
                if granted {
                    self?.setupMessageNotificationListener()
                    self?.scheduleRetentionNotifications()
                }
            }
            
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Settings
    private func loadNotificationSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let document = document, document.exists,
               let settingsData = document.data()?["notificationSettings"] as? [String: Any] {
                DispatchQueue.main.async {
                    self?.notificationSettings = NotificationSettings(from: settingsData)
                }
            }
        }
    }
    
    func updateNotificationSettings(_ settings: NotificationSettings) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        self.notificationSettings = settings
        
        let settingsData = settings.toDictionary()
        db.collection("users").document(userId).updateData([
            "notificationSettings": settingsData
        ]) { error in
            if let error = error {
                print("Error updating notification settings: \(error.localizedDescription)")
            }
        }
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
                        
                        // Kendi mesajlarımız için bildirim gönderme
                        if senderId != userId {
                            self.sendMessageNotification(messageData: messageData, conversationId: conversationId)
                        }
                    }
                }
            }
        
        notificationListeners.append(listener)
    }
    
    private func sendMessageNotification(messageData: [String: Any], conversationId: String) {
        guard notificationSettings.messageNotifications,
              let senderId = messageData["senderId"] as? String,
              let text = messageData["content"] as? String else { return }
        
        // Gönderen kullanıcının bilgilerini al
        db.collection("users").document(senderId).getDocument { [weak self] document, error in
            guard let self = self,
                  let document = document,
                  document.exists,
                  let userData = document.data() else { return }
            
            let senderName = userData["username"] as? String ?? "Bilinmeyen Kullanıcı"
            
            DispatchQueue.main.async {
                self.scheduleMessageNotification(
                    title: senderName,
                    body: text,
                    conversationId: conversationId,
                    senderId: senderId
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
        
        // Kullanıcı bilgilerini userInfo'ya ekle
        content.userInfo = [
            "type": "message",
            "conversationId": conversationId,
            "senderId": senderId
        ]
        
        // Hemen göster
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
        guard notificationSettings.retentionNotifications else { return }
        
        // Mevcut retention bildirimlerini temizle
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: getRetentionNotificationIds())
        
        let retentionMessages = [
            (hours: 24, message: "Arkadaşlarınızdan yeni mesajlar var! 💬"),
            (hours: 72, message: "Sizi özlüyoruz! Yeni gönderiler sizi bekliyor 📸"),
            (hours: 168, message: "Bu hafta neler kaçırdığınızı görün! 🌟"),
            (hours: 336, message: "Uzun zamandır gelmiyorsunuz. Topluluğunuz sizi bekliyor! 👥")
        ]
        
        for (index, retention) in retentionMessages.enumerated() {
            scheduleRetentionNotification(
                id: "retention_\(index)",
                title: "Lorien",
                body: retention.message,
                hoursFromNow: retention.hours
            )
        }
    }
    
    private func scheduleRetentionNotification(id: String, title: String, body: String, hoursFromNow: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        content.userInfo = [
            "type": "retention",
            "retentionType": id
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(hoursFromNow * 3600), repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling retention notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func getRetentionNotificationIds() -> [String] {
        return (0..<4).map { "retention_\($0)" }
    }
    
    // MARK: - Engagement Notifications
    func scheduleEngagementNotifications() {
        guard notificationSettings.engagementNotifications else { return }
        
        let engagementMessages = [
            (hours: 12, message: "Profilinizi güncelleyin ve daha fazla etkileşim alın! ✨"),
            (hours: 48, message: "Yeni bir gönderi paylaşmaya ne dersiniz? 📷"),
            (hours: 120, message: "Arkadaşlarınızı takip etmeyi unutmayın! 👫"),
            (hours: 240, message: "Hikayenizi paylaşın ve görünürlüğünüzü artırın! 🚀")
        ]
        
        for (index, engagement) in engagementMessages.enumerated() {
            scheduleEngagementNotification(
                id: "engagement_\(index)",
                title: "Lorien İpucu",
                body: engagement.message,
                hoursFromNow: engagement.hours
            )
        }
    }
    
    private func scheduleEngagementNotification(id: String, title: String, body: String, hoursFromNow: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        content.userInfo = [
            "type": "engagement",
            "engagementType": id
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(hoursFromNow * 3600), repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling engagement notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Social Notifications
    func sendSocialNotification(type: SocialNotificationType, from senderId: String, to receiverId: String? = nil, postId: String? = nil) {
        // Bildirim alacak kişinin ID'sini belirle
        let targetUserId = receiverId ?? Auth.auth().currentUser?.uid ?? ""
        
        // Kendi kendine bildirim gönderme
        guard senderId != targetUserId else { return }
        
        // Gönderen kullanıcının bilgilerini al
        db.collection("users").document(senderId).getDocument { [weak self] document, error in
            guard let self = self,
                  let document = document,
                  document.exists,
                  let userData = document.data() else { return }
            
            let senderName = userData["username"] as? String ?? "Bilinmeyen Kullanıcı"
            
            var shouldSend = false
            var title = ""
            var body = ""
            
            switch type {
            case .like:
                shouldSend = self.notificationSettings.likeNotifications
                title = "Yeni Beğeni"
                body = "\(senderName) gönderinizi beğendi ❤️"
            case .comment:
                shouldSend = self.notificationSettings.commentNotifications
                title = "Yeni Yorum"
                body = "\(senderName) gönderinize yorum yaptı 💬"
            case .follow:
                shouldSend = self.notificationSettings.followNotifications
                title = "Yeni Takipçi"
                body = "\(senderName) sizi takip etmeye başladı 👥"
            }
            
            if shouldSend {
                DispatchQueue.main.async {
                    self.scheduleSocialNotification(
                        title: title,
                        body: body,
                        type: type,
                        senderId: senderId,
                        postId: postId
                    )
                }
            }
        }
    }
    
    private func scheduleSocialNotification(title: String, body: String, type: SocialNotificationType, senderId: String, postId: String?) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        var userInfo: [String: Any] = [
            "type": "social",
            "socialType": type.rawValue,
            "senderId": senderId
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
    
    // MARK: - Cleanup
    private func removeAllListeners() {
        notificationListeners.forEach { $0.remove() }
        notificationListeners.removeAll()
    }
    
    func resetNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - Badge Management
    func updateBadgeCount() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Okunmamış mesaj sayısını hesapla
        db.collection("conversations")
            .whereField("users", arrayContains: userId)
            .getDocuments { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                
                var unreadCount = 0
                let group = DispatchGroup()
                
                for document in documents {
                    group.enter()
                    let conversationId = document.documentID
                    let conversationData = document.data()
                    let lastReadTimes = conversationData["lastReadTimes"] as? [String: Timestamp] ?? [:]
                    let userLastRead = lastReadTimes[userId]?.dateValue() ?? Date(timeIntervalSince1970: 0)
                    
                    // Bu konuşmadaki okunmamış mesajları say
                    self?.db.collection("conversations")
                        .document(conversationId)
                        .collection("messages")
                        .whereField("timestamp", isGreaterThan: userLastRead)
                        .whereField("senderId", isNotEqualTo: userId)
                        .getDocuments { querySnapshot, error in
                            if let documents = querySnapshot?.documents {
                                unreadCount += documents.count
                            }
                            group.leave()
                        }
                }
                
                group.notify(queue: .main) {
                    UIApplication.shared.applicationIconBadgeNumber = unreadCount
                }
            }
    }
    
    // MARK: - Test Functions
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Lorien Test"
        content.body = "Bildirim sistemi başarıyla aktif! 🎉"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "test_notification_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Test bildirimi gönderilirken hata: \(error.localizedDescription)")
            } else {
                print("Test bildirimi başarıyla gönderildi!")
            }
        }
    }
    
    func sendQuickRetentionTest() {
        let content = UNMutableNotificationContent()
        content.title = "Lorien"
        content.body = "Sizi özlüyoruz! Bu bir test bildirimidir. 💬"
        content.sound = .default
        
        // 5 saniye sonra göster
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "quick_test_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Hızlı test bildirimi gönderilirken hata: \(error.localizedDescription)")
            } else {
                print("Hızlı test bildirimi planlandı! 5 saniye sonra görünecek.")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Uygulama aktifken bildirimi göster
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "message":
                handleMessageNotificationTap(userInfo: userInfo)
            case "social":
                handleSocialNotificationTap(userInfo: userInfo)
            case "retention", "engagement":
                // Ana ekrana yönlendir
                NotificationCenter.default.post(name: NSNotification.Name("OpenMainApp"), object: nil)
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    private func handleMessageNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let conversationId = userInfo["conversationId"] as? String,
              let senderId = userInfo["senderId"] as? String else { return }
        
        // Mesaj ekranını aç
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenDirectMessageWithUser"),
            object: nil,
            userInfo: ["userId": senderId, "conversationId": conversationId]
        )
    }
    
    private func handleSocialNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let socialType = userInfo["socialType"] as? String,
              let senderId = userInfo["senderId"] as? String else { return }
        
        if let postId = userInfo["postId"] as? String {
            // Post detay ekranını aç
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenPost"),
                object: nil,
                userInfo: ["postId": postId]
            )
        } else {
            // Profil ekranını aç
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenProfile"),
                object: nil,
                userInfo: ["userId": senderId]
            )
        }
    }
}

// MARK: - Models
struct NotificationSettings {
    var pushNotifications: Bool = true
    var messageNotifications: Bool = true
    var likeNotifications: Bool = true
    var commentNotifications: Bool = true
    var followNotifications: Bool = true
    var retentionNotifications: Bool = true
    var engagementNotifications: Bool = true
    var emailNotifications: Bool = true
    var smsNotifications: Bool = false
    
    init() {}
    
    init(from dictionary: [String: Any]) {
        pushNotifications = dictionary["pushNotifications"] as? Bool ?? true
        messageNotifications = dictionary["messageNotifications"] as? Bool ?? true
        likeNotifications = dictionary["likeNotifications"] as? Bool ?? true
        commentNotifications = dictionary["commentNotifications"] as? Bool ?? true
        followNotifications = dictionary["followNotifications"] as? Bool ?? true
        retentionNotifications = dictionary["retentionNotifications"] as? Bool ?? true
        engagementNotifications = dictionary["engagementNotifications"] as? Bool ?? true
        emailNotifications = dictionary["emailNotifications"] as? Bool ?? true
        smsNotifications = dictionary["smsNotifications"] as? Bool ?? false
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "pushNotifications": pushNotifications,
            "messageNotifications": messageNotifications,
            "likeNotifications": likeNotifications,
            "commentNotifications": commentNotifications,
            "followNotifications": followNotifications,
            "retentionNotifications": retentionNotifications,
            "engagementNotifications": engagementNotifications,
            "emailNotifications": emailNotifications,
            "smsNotifications": smsNotifications
        ]
    }
}

enum SocialNotificationType: String, CaseIterable {
    case like = "like"
    case comment = "comment"
    case follow = "follow"
} 
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class InAppNotificationCoreService: ObservableObject {
    static let shared = InAppNotificationCoreService()
    
    @Published var notifications: [AppNotification] = []
    
    private let db = Firestore.firestore()
    private var notificationListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    private let duplicateService = InAppNotificationDuplicateService.shared
    private let badgeService = InAppNotificationBadgeService.shared
    
    init() {
        setupNotificationListener()
    }
    
    deinit {
        notificationListener?.remove()
    }
    
    // MARK: - Setup
    private func setupNotificationListener() {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("📱 ERROR: No current user for notification listener")
            return 
        }
        
        print("📱 DEBUG: Setting up notification listener for user: \(userId)")
        print("📱 DEBUG: User name should be checked to ensure correct user is logged in")
        
        // Check user document to verify identity
        db.collection("users").document(userId).getDocument { document, error in
            if let userData = document?.data(),
               let username = userData["username"] as? String {
                print("📱 DEBUG: Confirmed logged in user: \(username) (ID: \(userId))")
            }
        }
        
        notificationListener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50) // Limit to last 50 notifications
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else { return }
                
                print("📱 DEBUG: Received \(documents.count) notifications for user: \(userId)")
                
                DispatchQueue.main.async {
                    self.notifications = documents.compactMap { document in
                        if let notification = try? document.data(as: AppNotification.self) {
                            print("📱 Notification loaded: '\(notification.title)' - '\(notification.message)' - Target: \(notification.userId)")
                            
                            // Double check that this notification is for the current user
                            if notification.userId != userId {
                                print("⚠️ WARNING: Received notification for different user! Expected: \(userId), Got: \(notification.userId)")
                            }
                            
                            return notification
                        }
                        return nil
                    }
                    // Update badge count when notifications change
                    self.badgeService.updateBadgeCount(notifications: self.notifications)
                }
            }
    }
    
    // MARK: - Create Notifications
    func createNotification(
        for userId: String,
        type: AppNotification.NotificationType,
        title: String,
        message: String,
        data: [String: String]? = nil
    ) {
        print("📱 DEBUG: Creating in-app notification")
        print("   - Target user ID: \(userId)")
        print("   - Type: \(type.rawValue)")
        print("   - Title: \(title)")
        print("   - Message: \(message)")
        
        // Check for duplicate notifications to prevent spam
        let duplicateKey = duplicateService.generateDuplicateKey(userId: userId, type: type, data: data)
        
        if !duplicateService.shouldCreateNotification(duplicateKey: duplicateKey, type: type) {
            print("Skipping duplicate notification: \(duplicateKey)")
            return
        }
        
        let notification = AppNotification(
            userId: userId,
            type: type,
            title: title,
            message: message,
            data: data
        )
        
        do {
            let _ = try db.collection("notifications").addDocument(from: notification) { error in
                if let error = error {
                    print("Error creating notification: \(error.localizedDescription)")
                } else {
                    print("✅ Notification created successfully for user: \(userId)")
                    // Store the duplicate key to prevent future duplicates
                    self.duplicateService.storeDuplicateKey(duplicateKey)
                }
            }
        } catch {
            print("Error encoding notification: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Mark as Read
    func markAsRead(_ notification: AppNotification) {
        guard let notificationId = notification.id else { return }
        
        db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ]) { [weak self] error in
            if let error = error {
                print("Error marking notification as read: \(error.localizedDescription)")
            } else {
                // Update badge count after marking as read
                DispatchQueue.main.async {
                    self?.badgeService.updateBadgeCount(notifications: self?.notifications ?? [])
                }
            }
        }
    }
    
    func markAllAsRead() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let batch = db.batch()
        let unreadNotifications = notifications.filter { !$0.isRead }
        
        for notification in unreadNotifications {
            guard let notificationId = notification.id else { continue }
            let documentRef = db.collection("notifications").document(notificationId)
            batch.updateData(["isRead": true], forDocument: documentRef)
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                print("Error marking all notifications as read: \(error.localizedDescription)")
            } else {
                print("All notifications marked as read")
                // Update badge count after marking all as read
                DispatchQueue.main.async {
                    self?.badgeService.updateBadgeCount(notifications: self?.notifications ?? [])
                }
            }
        }
    }
    
    // MARK: - Delete Notifications
    func deleteNotification(_ notification: AppNotification) {
        guard let notificationId = notification.id else { return }
        
        db.collection("notifications").document(notificationId).delete { error in
            if let error = error {
                print("Error deleting notification: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteAllNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let batch = db.batch()
        
        for notification in notifications {
            guard let notificationId = notification.id else { continue }
            let documentRef = db.collection("notifications").document(notificationId)
            batch.deleteDocument(documentRef)
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                print("Error deleting all notifications: \(error.localizedDescription)")
            } else {
                print("All notifications deleted")
                // Update badge count after deleting all
                DispatchQueue.main.async {
                    self?.badgeService.updateBadgeCount(notifications: self?.notifications ?? [])
                }
            }
        }
    }
} 
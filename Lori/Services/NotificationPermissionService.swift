import Foundation
import UserNotifications
import UIKit

class NotificationPermissionService: NSObject, ObservableObject {
    static let shared = NotificationPermissionService()
    
    @Published var isNotificationsEnabled = false
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    // MARK: - Setup
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isNotificationsEnabled = granted
            }
            
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationPermissionService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "message":
                if let conversationId = userInfo["conversationId"] as? String {
                    // Handle message notification tap
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenConversation"),
                        object: nil,
                        userInfo: ["conversationId": conversationId]
                    )
                }
            case "retention":
                // Handle retention notification tap
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenApp"),
                    object: nil
                )
            default:
                break
            }
        }
        
        completionHandler()
    }
} 
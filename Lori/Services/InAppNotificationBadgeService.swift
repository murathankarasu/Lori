import Foundation
import Combine

class InAppNotificationBadgeService: ObservableObject {
    static let shared = InAppNotificationBadgeService()
    
    @Published var unreadCount: Int = 0
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Badge Management
    func updateBadgeCount(notifications: [AppNotification]) {
        // Calculate total unread count from both in-app notifications and messages
        let unreadNotificationCount = notifications.filter { !$0.isRead }.count
        
        // Also update message badge count via NotificationService
        NotificationService.shared.updateBadgeCount()
        
        // Set the total badge count (for now just using message count from NotificationService)
        // The NotificationService already handles the complete badge count calculation
        DispatchQueue.main.async {
            self.unreadCount = unreadNotificationCount
        }
    }
} 
import SwiftUI

struct NotificationBadgeView: View {
    @StateObject private var inAppNotificationService = InAppNotificationService.shared
    @StateObject private var notificationService = NotificationService.shared
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Image(systemName: "bell")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                
                // Badge with count - only show if notifications are enabled
                if shouldShowBadge && totalUnreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: badgeSize, height: badgeSize)
                        
                        Text(badgeText)
                            .font(.system(size: badgeFontSize, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 10, y: -10)
                }
            }
        }
        .onAppear {
            // Initialize the notification services when the badge appears
            // This ensures we start listening for notifications
        }
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowBadge: Bool {
        // Show badge only if notifications are enabled and relevant settings are on
        guard notificationService.isNotificationsEnabled && 
              notificationService.notificationSettings.pushNotifications else {
            return false
        }
        
        // Filter unread notifications based on notification settings
        let relevantUnreadCount = inAppNotificationService.notifications.filter { notification in
            if notification.isRead { return false }
            
            switch notification.type {
            case .message:
                return notificationService.notificationSettings.messageNotifications
            case .like:
                return notificationService.notificationSettings.likeNotifications
            case .comment:
                return notificationService.notificationSettings.commentNotifications
            case .follow:
                return notificationService.notificationSettings.followNotifications
            case .system, .welcome, .achievement:
                return true // System notifications are always shown
            }
        }.count
        
        return relevantUnreadCount > 0
    }
    
    private var totalUnreadCount: Int {
        // Calculate filtered unread count based on notification settings
        guard notificationService.isNotificationsEnabled && 
              notificationService.notificationSettings.pushNotifications else {
            return 0
        }
        
        return inAppNotificationService.notifications.filter { notification in
            if notification.isRead { return false }
            
            switch notification.type {
            case .message:
                return notificationService.notificationSettings.messageNotifications
            case .like:
                return notificationService.notificationSettings.likeNotifications
            case .comment:
                return notificationService.notificationSettings.commentNotifications
            case .follow:
                return notificationService.notificationSettings.followNotifications
            case .system, .welcome, .achievement:
                return true // System notifications are always counted
            }
        }.count
    }
    
    private var badgeSize: CGFloat {
        if totalUnreadCount > 99 {
            return 22
        } else if totalUnreadCount > 9 {
            return 20
        } else {
            return 18
        }
    }
    
    private var badgeFontSize: CGFloat {
        if totalUnreadCount > 99 {
            return 10
        } else if totalUnreadCount > 9 {
            return 11
        } else {
            return 12
        }
    }
    
    private var badgeText: String {
        if totalUnreadCount > 99 {
            return "99+"
        } else {
            return "\(totalUnreadCount)"
        }
    }
}

#Preview {
    ZStack {
        Color.black
        NotificationBadgeView {
            print("Notification tapped")
        }
    }
} 
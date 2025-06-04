import SwiftUI
import FirebaseAuth

struct NotificationCenterView: View {
    @StateObject private var notificationService = InAppNotificationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedNotification: AppNotification?
    @State private var showingActionSheet = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Header
                HStack(alignment: .center, spacing: 16) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("Notifications")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.top ?? 20 + 12)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Notifications List
                if notificationService.notifications.isEmpty {
                    EmptyNotificationsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(notificationService.notifications) { notification in
                                NotificationRowView(
                                    notification: notification,
                                    onTap: { handleNotificationTap(notification) },
                                    onDelete: { deleteNotification(notification) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .onAppear {
            // Debug info when view appears
            if let currentUserId = Auth.auth().currentUser?.uid {
                print("👤 DEBUG: NotificationCenterView opened by user: \(currentUserId)")
                print("👤 DEBUG: Showing \(notificationService.notifications.count) notifications")
                
                // Log all notifications currently displayed
                for (index, notification) in notificationService.notifications.enumerated() {
                    print("👤 Notification \(index + 1): '\(notification.message)' - Target: \(notification.userId)")
                }
            } else {
                print("👤 ERROR: No authenticated user when opening NotificationCenterView")
            }
        }
        .confirmationDialog("Delete all notifications?", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Delete All", role: .destructive) {
                notificationService.deleteAllNotifications()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func deleteNotification(_ notification: AppNotification) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            notificationService.deleteNotification(notification)
        }
    }
    
    private func handleNotificationTap(_ notification: AppNotification) {
        // Mark as read when tapped
        if !notification.isRead {
            notificationService.markAsRead(notification)
        }
        
        // Handle navigation based on notification type
        switch notification.type {
        case .like, .comment:
            if let postId = notification.data?["postId"] {
                // Navigate to post detail
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenPost"),
                    object: nil,
                    userInfo: ["postId": postId]
                )
                dismiss()
            }
        case .follow:
            if let senderId = notification.data?["senderId"] {
                // Navigate to user profile
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenProfile"),
                    object: nil,
                    userInfo: ["userId": senderId]
                )
                dismiss()
            }
        case .message:
            if let conversationId = notification.data?["conversationId"],
               let senderId = notification.data?["senderId"] {
                // Navigate to direct message
                NotificationCenter.default.post(
                    name: NSNotification.Name("OpenDirectMessageWithUser"),
                    object: nil,
                    userInfo: ["userId": senderId, "conversationId": conversationId]
                )
                dismiss()
            }
        case .system, .welcome, .achievement:
            // These notifications typically don't require navigation
            // Just mark as read (already done above)
            break
        }
    }
}

struct NotificationRowView: View {
    let notification: AppNotification
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: notification.iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(notification.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                // Message
                Text(notification.message)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                // Timestamp
                Text(timeAgo(from: notification.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.7))
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.07))
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private var iconBackgroundColor: Color {
        switch notification.iconColor {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "yellow": return .yellow
        default: return .gray
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear], from: date, to: now)
        
        if let weeks = components.weekOfYear, weeks > 0 {
            return "\(weeks)w"
        } else if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Now"
        }
    }
}

struct EmptyNotificationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding(.bottom, 20)
            
            Text("No notifications yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("New notifications will appear here")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

#Preview {
    NotificationCenterView()
} 
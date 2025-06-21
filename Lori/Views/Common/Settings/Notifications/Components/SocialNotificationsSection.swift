import SwiftUI

struct SocialNotificationsSection: View {
    @ObservedObject var notificationService: NotificationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Social Notifications", icon: "person.2.circle.fill")
            
            VStack(spacing: 0) {
                ModernNotificationToggleRow(
                    title: "Direct message notifications",
                    subtitle: "Notifications for direct messages",
                    icon: "message.fill",
                    iconColor: .purple,
                    isOn: Binding(
                        get: { notificationService.notificationSettings.directMessageNotifications },
                        set: { newValue in
                            notificationService.notificationSettings.directMessageNotifications = newValue
                            notificationService.updateNotificationSettings(notificationService.notificationSettings)
                        }
                    ),
                    isFirst: true
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                ModernNotificationToggleRow(
                    title: "New Followers",
                    subtitle: "Users who follow you",
                    icon: "person.crop.circle.badge.plus",
                    iconColor: .teal,
                    isOn: Binding(
                        get: { notificationService.notificationSettings.newFollowers },
                        set: { newValue in
                            notificationService.notificationSettings.newFollowers = newValue
                            notificationService.updateNotificationSettings(notificationService.notificationSettings)
                        }
                    )
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                ModernNotificationToggleRow(
                    title: "Likes",
                    subtitle: "Likes on your posts",
                    icon: "heart.fill",
                    iconColor: .red,
                    isOn: Binding(
                        get: { notificationService.notificationSettings.likes },
                        set: { newValue in
                            notificationService.notificationSettings.likes = newValue
                            notificationService.updateNotificationSettings(notificationService.notificationSettings)
                        }
                    ),
                    isLast: true
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
} 

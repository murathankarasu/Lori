import SwiftUI

struct GeneralNotificationsSection: View {
    @ObservedObject var notificationService: NotificationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "General Notifications", icon: "bell.circle.fill")
            
            VStack(spacing: 0) {
                ModernNotificationToggleRow(
                    title: "Push Notifications",
                    subtitle: "Master switch for all notifications",
                    icon: "bell.fill",
                    iconColor: .blue,
                    isOn: Binding(
                        get: { notificationService.notificationSettings.pushNotifications },
                        set: { newValue in
                            notificationService.notificationSettings.pushNotifications = newValue
                            notificationService.updateNotificationSettings(notificationService.notificationSettings)
                        }
                    ),
                    isFirst: true
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                ModernNotificationToggleRow(
                    title: "Email Notifications",
                    subtitle: "Receive notifications via email",
                    icon: "envelope.fill",
                    iconColor: .green,
                    isOn: Binding(
                        get: { notificationService.notificationSettings.emailNotifications },
                        set: { newValue in
                            notificationService.notificationSettings.emailNotifications = newValue
                            notificationService.updateNotificationSettings(notificationService.notificationSettings)
                        }
                    )
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                ModernNotificationToggleRow(
                    title: "SMS Notifications",
                    subtitle: "Receive notifications via SMS",
                    icon: "message.fill",
                    iconColor: .orange,
                    isOn: Binding(
                        get: { notificationService.notificationSettings.smsNotifications },
                        set: { newValue in
                            notificationService.notificationSettings.smsNotifications = newValue
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
import SwiftUI

struct RetentionNotificationsSection: View {
    @ObservedObject var notificationService: NotificationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Retention Notifications", icon: "clock.fill")
            
            VStack(spacing: 0) {
                ModernNotificationToggleRow(
                    title: "Daily Reminders",
                    subtitle: "Receive daily reminders",
                    icon: "calendar",
                    iconColor: .yellow,
                    isOn: Binding(
                        get: { notificationService.notificationSettings.dailyReminders },
                        set: { newValue in
                            notificationService.notificationSettings.dailyReminders = newValue
                            notificationService.updateNotificationSettings(notificationService.notificationSettings)
                        }
                    ),
                    isFirst: true
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                ModernNotificationToggleRow(
                    title: "Weekly Summary",
                    subtitle: "Summary of weekly activity",
                    icon: "chart.bar.fill",
                    iconColor: .blue,
                    isOn: Binding(
                        get: { notificationService.notificationSettings.weeklySummary },
                        set: { newValue in
                            notificationService.notificationSettings.weeklySummary = newValue
                            notificationService.updateNotificationSettings(notificationService.notificationSettings)
                        }
                    )
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                ModernNotificationToggleRow(
                    title: "Monthly Report",
                    subtitle: "Detailed monthly report",
                    icon: "doc.text.fill",
                    iconColor: .green,
                    isOn: Binding(
                        get: { notificationService.notificationSettings.monthlyReport },
                        set: { newValue in
                            notificationService.notificationSettings.monthlyReport = newValue
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
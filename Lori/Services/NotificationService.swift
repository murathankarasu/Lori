import Foundation
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import UIKit
import Combine

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isNotificationsEnabled = false
    @Published var notificationSettings: NotificationSettings = NotificationSettings()
    
    private let permissionService = NotificationPermissionService.shared
    private let settingsService = NotificationSettingsService.shared
    private let coreService = NotificationCoreService.shared
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Forward notification permission status
        permissionService.$isNotificationsEnabled
            .assign(to: \.isNotificationsEnabled, on: self)
            .store(in: &cancellables)
        
        // Forward notification settings
        settingsService.$notificationSettings
            .assign(to: \.notificationSettings, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func requestNotificationPermission() {
        permissionService.requestNotificationPermission()
    }
    
    func updateNotificationSettings(_ settings: NotificationSettings) {
        settingsService.updateNotificationSettings(settings)
    }
    
    func applicationWillEnterForeground() {
        coreService.applicationWillEnterForeground()
    }
    
    func scheduleRetentionNotifications() {
        coreService.scheduleRetentionNotifications()
    }
    
    func updateBadgeCount() {
        coreService.updateBadgeCount()
    }
    
    // MARK: - Social Notifications
    func sendSocialNotification(type: SocialNotificationType, from senderId: String, to receiverId: String? = nil, postId: String? = nil) {
        coreService.sendSocialNotification(type: type, from: senderId, to: receiverId, postId: postId)
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
    var dailyReminders: Bool = true
    var weeklySummary: Bool = true
    var monthlyReport: Bool = true
    var directMessageNotifications: Bool = true
    var newFollowers: Bool = true
    var likes: Bool = true
    
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
        dailyReminders = dictionary["dailyReminders"] as? Bool ?? true
        weeklySummary = dictionary["weeklySummary"] as? Bool ?? true
        monthlyReport = dictionary["monthlyReport"] as? Bool ?? true
        directMessageNotifications = dictionary["directMessageNotifications"] as? Bool ?? true
        newFollowers = dictionary["newFollowers"] as? Bool ?? true
        likes = dictionary["likes"] as? Bool ?? true
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
            "smsNotifications": smsNotifications,
            "dailyReminders": dailyReminders,
            "weeklySummary": weeklySummary,
            "monthlyReport": monthlyReport,
            "directMessageNotifications": directMessageNotifications,
            "newFollowers": newFollowers,
            "likes": likes
        ]
    }
}

enum SocialNotificationType: String, CaseIterable {
    case like = "like"
    case comment = "comment"
    case follow = "follow"
} 
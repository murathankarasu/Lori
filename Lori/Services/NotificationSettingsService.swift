import Foundation
import FirebaseAuth
import FirebaseFirestore

class NotificationSettingsService: ObservableObject {
    static let shared = NotificationSettingsService()
    
    @Published var notificationSettings: NotificationSettings = NotificationSettings()
    
    private let db = Firestore.firestore()
    
    init() {
        loadNotificationSettings()
    }
    
    // MARK: - Settings Management
    func loadNotificationSettings() {
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
    
    // MARK: - Settings Validation
    func validateSettings(_ settings: NotificationSettings) -> Bool {
        // Add any validation logic here
        return true
    }
    
    // MARK: - Settings Reset
    func resetToDefaultSettings() {
        let defaultSettings = NotificationSettings()
        updateNotificationSettings(defaultSettings)
    }
} 
import UIKit
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Bildirim servisi başlatma
        _ = NotificationService.shared
        
        Task {
            await FirestoreIndexes.createIndexes()
        }
        
        return true
    }
    
    // Bildirim izni durumu değiştiğinde
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Push notification token'ı işle (gerekirse)
        print("Push notification token alındı: \(deviceToken)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Push notification kaydı başarısız: \(error.localizedDescription)")
    }
    
    // Uygulama arka plana geçtiğinde
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Rozet sayısını güncelle
        NotificationService.shared.updateBadgeCount()
    }
    
    // Uygulama ön plana geldiğinde
    func applicationWillEnterForeground(_ application: UIApplication) {
        // NotificationService'e uygulama ön plana geldiğini bildir
        NotificationService.shared.applicationWillEnterForeground()
        
        // Rozet sayısını sıfırla
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // Force portrait orientation
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
} 

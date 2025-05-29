import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct NotificationsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @State private var showingQuietHours = false
    @State private var showingCustomNotifications = false
    @Environment(\.dismiss) private var dismiss
    
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
                // Custom Header with Back Button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Geri")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Text("Bildirimler")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible placeholder for balance
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 80, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Genel Bildirimler
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "bell.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Genel Bildirimler")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 25)
                            
                            VStack(spacing: 0) {
                                ModernNotificationToggleRow(
                                    title: "Push Bildirimleri",
                                    subtitle: "Tüm bildirimler için ana anahtar",
                                    icon: "bell.fill",
                                    iconColor: .blue,
                                    isOn: Binding(
                                        get: { notificationService.notificationSettings.pushNotifications },
                                        set: { newValue in
                                            notificationService.notificationSettings.pushNotifications = newValue
                                            updateSettings()
                                        }
                                    ),
                                    isFirst: true
                                )
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                ModernNotificationToggleRow(
                                    title: "E-posta Bildirimleri",
                                    subtitle: "E-posta ile bildirim alın",
                                    icon: "envelope.fill",
                                    iconColor: .green,
                                    isOn: Binding(
                                        get: { notificationService.notificationSettings.emailNotifications },
                                        set: { newValue in
                                            notificationService.notificationSettings.emailNotifications = newValue
                                            updateSettings()
                                        }
                                    )
                                )
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                ModernNotificationToggleRow(
                                    title: "SMS Bildirimleri",
                                    subtitle: "SMS ile bildirim alın",
                                    icon: "message.fill",
                                    iconColor: .orange,
                                    isOn: Binding(
                                        get: { notificationService.notificationSettings.smsNotifications },
                                        set: { newValue in
                                            notificationService.notificationSettings.smsNotifications = newValue
                                            updateSettings()
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
                        
                        // Sosyal Bildirimler
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "person.2.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Sosyal Bildirimler")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 25)
                            
                            VStack(spacing: 0) {
                                ModernNotificationToggleRow(
                                    title: "Yeni Mesajlar",
                                    subtitle: "Özel mesaj bildirimleri",
                                    icon: "message.fill",
                                    iconColor: .purple,
                                    isOn: Binding(
                                        get: { notificationService.notificationSettings.messageNotifications },
                                        set: { newValue in
                                            notificationService.notificationSettings.messageNotifications = newValue
                                            updateSettings()
                                        }
                                    ),
                                    isFirst: true
                                )
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                ModernNotificationToggleRow(
                                    title: "Yeni Takipçiler",
                                    subtitle: "Sizi takip eden kullanıcılar",
                                    icon: "person.badge.plus.fill",
                                    iconColor: .mint,
                                    isOn: Binding(
                                        get: { notificationService.notificationSettings.followNotifications },
                                        set: { newValue in
                                            notificationService.notificationSettings.followNotifications = newValue
                                            updateSettings()
                                        }
                                    )
                                )
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                ModernNotificationToggleRow(
                                    title: "Beğeniler",
                                    subtitle: "Gönderilerinize yapılan beğeniler",
                                    icon: "heart.fill",
                                    iconColor: .pink,
                                    isOn: Binding(
                                        get: { notificationService.notificationSettings.likeNotifications },
                                        set: { newValue in
                                            notificationService.notificationSettings.likeNotifications = newValue
                                            updateSettings()
                                        }
                                    )
                                )
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                ModernNotificationToggleRow(
                                    title: "Yorumlar",
                                    subtitle: "Gönderilerinize yapılan yorumlar",
                                    icon: "bubble.left.fill",
                                    iconColor: .cyan,
                                    isOn: Binding(
                                        get: { notificationService.notificationSettings.commentNotifications },
                                        set: { newValue in
                                            notificationService.notificationSettings.commentNotifications = newValue
                                            updateSettings()
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
                        
                        // Kullanıcı Tutma Bildirimleri
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Geri Dönüş Bildirimleri")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 25)
                            
                            VStack(spacing: 0) {
                                ModernNotificationToggleRow(
                                    title: "Geri Dönüş Hatırlatmaları",
                                    subtitle: "Uzun süre girmediğinizde hatırlatma mesajları",
                                    icon: "clock.arrow.circlepath",
                                    iconColor: .indigo,
                                    isOn: Binding(
                                        get: { notificationService.notificationSettings.retentionNotifications },
                                        set: { newValue in
                                            notificationService.notificationSettings.retentionNotifications = newValue
                                            updateSettings()
                                            if newValue {
                                                notificationService.scheduleRetentionNotifications()
                                            }
                                        }
                                    ),
                                    isFirst: true
                                )
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                ModernNotificationToggleRow(
                                    title: "Etkileşim İpuçları",
                                    subtitle: "Uygulamayı daha iyi kullanmanız için öneriler",
                                    icon: "lightbulb.fill",
                                    iconColor: .yellow,
                                    isOn: Binding(
                                        get: { notificationService.notificationSettings.engagementNotifications },
                                        set: { newValue in
                                            notificationService.notificationSettings.engagementNotifications = newValue
                                            updateSettings()
                                            if newValue {
                                                notificationService.scheduleEngagementNotifications()
                                            }
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
                        
                        // Gelişmiş Ayarlar
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Gelişmiş Ayarlar")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 25)
                            
                            VStack(spacing: 0) {
                                Button(action: {
                                    showingQuietHours = true
                                }) {
                                    ModernSettingsRow(
                                        title: "Sessiz Saatler",
                                        subtitle: "Belirli saatlerde bildirimleri susturun",
                                        icon: "moon.fill",
                                        iconColor: .indigo,
                                        isFirst: true
                                    )
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                Button(action: {
                                    notificationService.sendTestNotification()
                                }) {
                                    ModernSettingsRow(
                                        title: "Test Bildirimi Gönder",
                                        subtitle: "Bildirimlerin çalışıp çalışmadığını test edin",
                                        icon: "bell.badge.fill",
                                        iconColor: .green
                                    )
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                Button(action: {
                                    notificationService.sendQuickRetentionTest()
                                }) {
                                    ModernSettingsRow(
                                        title: "Hızlı Test (5 saniye)",
                                        subtitle: "5 saniye sonra gelen test bildirimi",
                                        icon: "timer.circle.fill",
                                        iconColor: .orange
                                    )
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                Button(action: {
                                    notificationService.updateBadgeCount()
                                }) {
                                    ModernSettingsRow(
                                        title: "Rozet Sayısını Güncelle",
                                        subtitle: "Okunmamış mesaj sayısını yenile",
                                        icon: "app.badge.fill",
                                        iconColor: .red
                                    )
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                Button(action: {
                                    notificationService.resetNotifications()
                                }) {
                                    ModernSettingsRow(
                                        title: "Bildirimleri Temizle",
                                        subtitle: "Tüm bekleyen bildirimleri sil",
                                        icon: "trash.circle.fill",
                                        iconColor: .red,
                                        isLast: true,
                                        isDestructive: true
                                    )
                                }
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
                        
                        // Bildirim Durumu
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: notificationService.isNotificationsEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(notificationService.isNotificationsEnabled ? .green : .red)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Bildirim İzni")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(notificationService.isNotificationsEnabled ? "Aktif" : "Kapalı - Ayarlardan açabilirsiniz")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingQuietHours) {
            QuietHoursView()
        }
        .sheet(isPresented: $showingCustomNotifications) {
            CustomNotificationsView()
        }
    }
    
    private func updateSettings() {
        notificationService.updateNotificationSettings(notificationService.notificationSettings)
    }
}

// MARK: - ViewModel
class NotificationsViewModel: ObservableObject {
    @Published var pushNotifications = true
    @Published var emailNotifications = true
    @Published var smsNotifications = false
    @Published var messageNotifications = true
    @Published var postNotifications = true
    @Published var commentNotifications = true
    @Published var likeNotifications = true
    
    init() {
        loadNotificationSettings()
    }
    
    private func loadNotificationSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                if let settings = document.data()?["notificationSettings"] as? [String: Any] {
                    DispatchQueue.main.async {
                        self?.pushNotifications = settings["pushNotifications"] as? Bool ?? true
                        self?.emailNotifications = settings["emailNotifications"] as? Bool ?? true
                        self?.smsNotifications = settings["smsNotifications"] as? Bool ?? false
                        self?.messageNotifications = settings["messageNotifications"] as? Bool ?? true
                        self?.postNotifications = settings["postNotifications"] as? Bool ?? true
                        self?.commentNotifications = settings["commentNotifications"] as? Bool ?? true
                        self?.likeNotifications = settings["likeNotifications"] as? Bool ?? true
                    }
                }
            }
        }
    }
    
    func updateNotificationSettings() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let settings: [String: Any] = [
            "pushNotifications": pushNotifications,
            "emailNotifications": emailNotifications,
            "smsNotifications": smsNotifications,
            "messageNotifications": messageNotifications,
            "postNotifications": postNotifications,
            "commentNotifications": commentNotifications,
            "likeNotifications": likeNotifications
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "notificationSettings": settings
        ]) { error in
            if let error = error {
                print("Error updating notification settings: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Alt View'lar
struct QuietHoursView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isEnabled = false
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Sessiz Saatler Açma/Kapama
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Sessiz Saatler")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Toggle("Sessiz Saatleri Etkinleştir", isOn: $isEnabled)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                            .padding(.horizontal)
                    }
                    
                    if isEnabled {
                        // Başlangıç Saati
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Başlangıç Saati")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            DatePicker("Başlangıç", selection: $startTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(15)
                                .padding(.horizontal)
                        }
                        
                        // Bitiş Saati
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Bitiş Saati")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            DatePicker("Bitiş", selection: $endTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(15)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Quiet Hours")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    // Sessiz saatleri kaydet
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
    }
}

struct CustomNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var customNotifications: [CustomNotification] = []
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Özel Bildirim Listesi
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Özel Bildirimler")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ForEach(customNotifications) { notification in
                            CustomNotificationRow(notification: notification)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Yeni Bildirim Ekleme Butonu
                    Button(action: {
                        // Yeni bildirim ekleme
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                            
                            Text("Yeni Bildirim Ekle")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Custom Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    // Özel bildirimleri kaydet
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
    }
}

struct CustomNotificationRow: View {
    let notification: CustomNotification
    @State private var isEnabled = true
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(notification.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .tint(.white)
        }
    }
}

// MARK: - Model
struct CustomNotification: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    var isEnabled: Bool
} 

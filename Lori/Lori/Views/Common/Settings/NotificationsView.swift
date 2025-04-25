import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @State private var showingQuietHours = false
    @State private var showingCustomNotifications = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Genel Bildirimler
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Genel Bildirimler")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            NotificationToggleRow(
                                title: "Push Bildirimleri",
                                icon: "bell.fill",
                                isOn: $viewModel.pushNotifications
                            )
                            
                            NotificationToggleRow(
                                title: "E-posta Bildirimleri",
                                icon: "envelope.fill",
                                isOn: $viewModel.emailNotifications
                            )
                            
                            NotificationToggleRow(
                                title: "SMS Bildirimleri",
                                icon: "message.fill",
                                isOn: $viewModel.smsNotifications
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Bildirim Türleri
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Bildirim Türleri")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            NotificationToggleRow(
                                title: "Yeni Mesajlar",
                                icon: "message.fill",
                                isOn: $viewModel.messageNotifications
                            )
                            
                            NotificationToggleRow(
                                title: "Yeni Gönderiler",
                                icon: "photo.fill",
                                isOn: $viewModel.postNotifications
                            )
                            
                            NotificationToggleRow(
                                title: "Yorumlar",
                                icon: "bubble.left.fill",
                                isOn: $viewModel.commentNotifications
                            )
                            
                            NotificationToggleRow(
                                title: "Beğeniler",
                                icon: "heart.fill",
                                isOn: $viewModel.likeNotifications
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Sessiz Saatler
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Sessiz Saatler")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingQuietHours = true
                        }) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                                
                                Text("Sessiz Saatleri Yönet")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Özel Bildirimler
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Özel Bildirimler")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingCustomNotifications = true
                        }) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                                
                                Text("Özel Bildirimleri Yönet")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Bildirimler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingQuietHours) {
            QuietHoursView()
        }
        .sheet(isPresented: $showingCustomNotifications) {
            CustomNotificationsView()
        }
    }
}

struct NotificationToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.title2)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(.white)
        }
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
        .navigationTitle("Sessiz Saatler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Kaydet") {
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
        .navigationTitle("Özel Bildirimler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Kaydet") {
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

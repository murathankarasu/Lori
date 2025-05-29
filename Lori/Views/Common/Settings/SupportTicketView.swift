import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SupportTicketView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var message = ""
    @State private var selectedCategory = SupportCategory.bug
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
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
                    
                    Text("Destek Talebi")
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
                        // Form Section
                        VStack(alignment: .leading, spacing: 25) {
                            // Category Selection
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Konu Kategorisi")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(SupportCategory.allCases, id: \.self) { category in
                                        CategoryCard(
                                            category: category,
                                            isSelected: selectedCategory == category
                                        ) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                            }
                            
                            // Title Input
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Konu Başlığı")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                TextField("Sorunuzu kısaca özetleyin...", text: $title)
                                    .textFieldStyle(ModernTextFieldStyle())
                            }
                            
                            // Message Input
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Detaylı Açıklama")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $message)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .background(Color.clear)
                                        .frame(minHeight: 120)
                                    
                                    if message.isEmpty {
                                        Text("Sorununuzu detaylıca açıklayın. Ne yapmaya çalışıyordunuz? Hangi hata ile karşılaştınız?")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.5))
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // Submit Button
                            Button(action: {
                                Task {
                                    await submitTicket()
                                }
                            }) {
                                HStack {
                                    if isSubmitting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    
                                    Text(isSubmitting ? "Gönderiliyor..." : "Destek Talebi Gönder")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(isSubmitting || title.isEmpty || message.isEmpty)
                            .opacity(isSubmitting || title.isEmpty || message.isEmpty ? 0.6 : 1.0)
                        }
                        .padding(.horizontal, 20)
                        
                        // Info Section
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                
                                Text("Bilgi")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                InfoRow(
                                    icon: "clock.fill",
                                    text: "Destek talebiniz 24-48 saat içinde yanıtlanacaktır",
                                    color: .green
                                )
                                
                                InfoRow(
                                    icon: "shield.checkered",
                                    text: "Tüm talepler gizli olarak işleme alınır",
                                    color: .orange
                                )
                                
                                InfoRow(
                                    icon: "envelope.fill",
                                    text: "Yanıt kayıtlı e-posta adresinize gönderilecektir",
                                    color: .purple
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
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
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Başarılı", isPresented: $showSuccessAlert) {
            Button("Tamam") {
                dismiss()
            }
        } message: {
            Text("Destek talebiniz başarıyla gönderildi. En kısa sürede size dönüş yapacağız.")
        }
        .alert("Hata", isPresented: $showErrorAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func submitTicket() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Kullanıcı oturumu gerekli"
            showErrorAlert = true
            return
        }
        
        isSubmitting = true
        
        do {
            let ticket = SupportTicket(
                id: nil,
                userId: userId,
                category: selectedCategory,
                title: title,
                message: message,
                status: .open,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            let db = Firestore.firestore()
            try db.collection("supportTickets").addDocument(from: ticket)
            
            // Başarı bildirimi
            showSuccessAlert = true
            
        } catch {
            errorMessage = "Destek talebi gönderilemedi: \(error.localizedDescription)"
            showErrorAlert = true
        }
        
        isSubmitting = false
    }
}

// MARK: - Supporting Views
struct CategoryCard: View {
    let category: SupportCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(category.color)
                }
                
                Text(category.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? category.color.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? category.color : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Models
struct SupportTicket: Identifiable, Codable {
    var id: String?
    let userId: String
    let category: SupportCategory
    let title: String
    let message: String
    let status: TicketStatus
    let createdAt: Date
    let updatedAt: Date
}

enum SupportCategory: String, CaseIterable, Codable {
    case bug = "bug"
    case feature = "feature"
    case account = "account"
    case payment = "payment"
    case content = "content"
    case other = "other"
    
    var title: String {
        switch self {
        case .bug: return "Hata Bildirimi"
        case .feature: return "Özellik Talebi"
        case .account: return "Hesap Sorunu"
        case .payment: return "Ödeme Sorunu"
        case .content: return "İçerik Sorunu"
        case .other: return "Diğer"
        }
    }
    
    var icon: String {
        switch self {
        case .bug: return "ladybug.fill"
        case .feature: return "lightbulb.fill"
        case .account: return "person.circle.fill"
        case .payment: return "creditcard.fill"
        case .content: return "photo.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .bug: return .red
        case .feature: return .blue
        case .account: return .green
        case .payment: return .orange
        case .content: return .purple
        case .other: return .gray
        }
    }
}

enum TicketStatus: String, Codable {
    case open = "open"
    case inProgress = "in_progress"
    case resolved = "resolved"
    case closed = "closed"
}

// Dosya Seçici View
struct FilePickerView: View {
    @Binding var selectedFile: URL?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Dosya Seç")
                    .font(.title2)
                    .foregroundColor(.white)
                
                // Dosya seçme seçenekleri
                VStack(spacing: 15) {
                    FileOptionButton(title: "Galeriden Seç", icon: "photo.on.rectangle", action: {
                        // Galeri seçimi
                    })
                    
                    FileOptionButton(title: "Dosyadan Seç", icon: "doc", action: {
                        // Dosya seçimi
                    })
                    
                    FileOptionButton(title: "Kameradan Çek", icon: "camera", action: {
                        // Kamera seçimi
                    })
                }
                .padding()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("İptal")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FileOptionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                Text(title)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
} 
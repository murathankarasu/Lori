import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SupportTicketView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Başlık
                    TextField("Destek Talebi Başlığı", text: $title)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    // Açıklama
                    TextEditor(text: $description)
                        .frame(height: 200)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    // Gönder Butonu
                    Button(action: {
                        submitTicket()
                    }) {
                        Text("Gönder")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(25)
                    }
                    .padding(.horizontal)
                    .disabled(title.isEmpty || description.isEmpty || isLoading)
                    
                    // Bilgi Metni
                    Text("Destek talebiniz en kısa sürede yanıtlanacaktır.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Destek Talebi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Bilgi", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) {
                if alertMessage.contains("başarıyla") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
            }
        }
    }
    
    private func submitTicket() {
        isLoading = true
        
        // Simüle edilmiş API çağrısı
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            alertMessage = "Destek talebiniz başarıyla gönderildi."
            showAlert = true
        }
    }
}

// MARK: - Model
struct SupportTicket {
    let userId: String
    let userEmail: String
    let category: String
    let subject: String
    let message: String
    let status: String
    let createdAt: Date
    
    var dictionary: [String: Any] {
        return [
            "userId": userId,
            "userEmail": userEmail,
            "category": category,
            "subject": subject,
            "message": message,
            "status": status,
            "createdAt": createdAt
        ]
    }
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
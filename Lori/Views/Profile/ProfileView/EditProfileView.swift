import SwiftUI
import FirebaseFirestore

struct EditProfileView: View {
    let user: User?
    @Binding var bio: String
    @Binding var username: String
    @Binding var profileImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Profil fotoğrafı
                    Button(action: {}) {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.white)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                    }
                    
                    // Kullanıcı adı
                    TextField("Kullanıcı Adı", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // Bio
                    TextEditor(text: $bio)
                        .frame(height: 100)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Kaydet butonu
                    Button(action: saveProfile) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Kaydet")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(25)
                        }
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Bilgi"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Tamam")) {
                    if alertMessage.contains("başarıyla") {
                        dismiss()
                    }
                }
            )
        }
    }
    
    private func saveProfile() {
        guard let userId = user?.id else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        
        // Profil fotoğrafını yükle
        if let image = profileImage {
            // Firebase Storage'a fotoğraf yükleme işlemi burada yapılacak
            // Şimdilik örnek bir URL kullanıyoruz
            let imageUrl = "https://example.com/profile.jpg"
            
            // Kullanıcı bilgilerini güncelle
            db.collection("users").document(userId).updateData([
                "username": username,
                "bio": bio,
                "profileImageUrl": imageUrl
            ]) { error in
                isLoading = false
                
                if let error = error {
                    alertMessage = "Profil güncellenirken bir hata oluştu: \(error.localizedDescription)"
                } else {
                    alertMessage = "Profil başarıyla güncellendi!"
                }
                
                showAlert = true
            }
        } else {
            // Sadece metin bilgilerini güncelle
            db.collection("users").document(userId).updateData([
                "username": username,
                "bio": bio
            ]) { error in
                isLoading = false
                
                if let error = error {
                    alertMessage = "Profil güncellenirken bir hata oluştu: \(error.localizedDescription)"
                } else {
                    alertMessage = "Profil başarıyla güncellendi!"
                }
                
                showAlert = true
            }
        }
    }
} 
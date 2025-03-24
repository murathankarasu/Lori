import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var postContent = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var hateSpeechResult: HateSpeechResponse?
    @State private var isCheckingHateSpeech = false
    @State private var debounceTimer: Timer?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Gönderi içeriği
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Gönderi İçeriği")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $postContent)
                                .frame(height: 150)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .onChange(of: postContent) { oldValue, newValue in
                                    // Debounce timer'ı iptal et
                                    debounceTimer?.invalidate()
                                    
                                    // Yeni timer başlat
                                    debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                                        checkHateSpeech()
                                    }
                                }
                            
                            // Nefret söylemi kontrolü sonucu
                            if let result = hateSpeechResult {
                                HStack {
                                    Image(systemName: result.isHateSpeech ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                        .foregroundColor(result.isHateSpeech ? .red : .green)
                                    Text(result.isHateSpeech ? "Nefret söylemi tespit edildi!" : "Güvenli içerik")
                                        .foregroundColor(result.isHateSpeech ? .red : .green)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Fotoğraf ekleme butonu
                        Button(action: { showImagePicker = true }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Fotoğraf Ekle")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(25)
                        }
                        .padding(.horizontal)
                        
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Yeni Gönderi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Paylaş") {
                        checkAndCreatePost()
                    }
                    .disabled(isLoading || postContent.isEmpty || (hateSpeechResult?.isHateSpeech ?? false))
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
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
    
    private func checkHateSpeech() {
        guard !postContent.isEmpty else { return }
        
        isCheckingHateSpeech = true
        
        Task {
            do {
                let result = try await HateSpeechService.shared.debouncedCheck(text: postContent)
                await MainActor.run {
                    isCheckingHateSpeech = false
                    hateSpeechResult = result
                    
                    if result.isHateSpeech {
                        alertMessage = "Bu içerik nefret söylemi içeriyor. Lütfen içeriğinizi düzenleyin."
                        showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingHateSpeech = false
                    alertMessage = "Nefret söylemi kontrolü sırasında bir hata oluştu: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func checkAndCreatePost() {
        isLoading = true
        
        // Önce nefret söylemi kontrolü yap
        checkHateSpeech()
        
        // Gönderiyi oluştur
        let post = Post(
            id: UUID().uuidString,
            userId: Auth.auth().currentUser?.uid ?? "",
            username: Auth.auth().currentUser?.displayName ?? "Anonim",
            content: postContent,
            imageUrl: nil,
            timestamp: Date(),
            likes: 0,
            comments: [],
            isViewed: false,
            tags: []
        )
        
        // Firebase'e kaydet
        let db = Firestore.firestore()
        
        // Önce fotoğrafı yükle
        if let image = selectedImage {
            // Firebase Storage'a fotoğraf yükleme işlemi burada yapılacak
            // Şimdilik örnek bir URL kullanıyoruz
            let imageUrl = "https://example.com/post.jpg"
            
            // Gönderiyi kaydet
            db.collection("posts").document(post.id).setData([
                "id": post.id,
                "userId": post.userId,
                "username": post.username,
                "content": post.content,
                "imageUrl": imageUrl,
                "timestamp": Timestamp(date: post.timestamp),
                "likes": post.likes,
                "comments": [],
                "isFeatured": false
            ]) { error in
                isLoading = false
                
                if let error = error {
                    alertMessage = "Gönderi paylaşılırken bir hata oluştu: \(error.localizedDescription)"
                } else {
                    alertMessage = "Gönderi başarıyla paylaşıldı!"
                }
                
                showAlert = true
            }
        } else {
            // Fotoğraf olmadan gönderiyi kaydet
            db.collection("posts").document(post.id).setData([
                "id": post.id,
                "userId": post.userId,
                "username": post.username,
                "content": post.content,
                "timestamp": Timestamp(date: post.timestamp),
                "likes": post.likes,
                "comments": [],
                "isFeatured": false
            ]) { error in
                isLoading = false
                
                if let error = error {
                    alertMessage = "Gönderi paylaşılırken bir hata oluştu: \(error.localizedDescription)"
                } else {
                    alertMessage = "Gönderi başarıyla paylaşıldı!"
                }
                
                showAlert = true
            }
        }
    }
}

struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
    }
} 
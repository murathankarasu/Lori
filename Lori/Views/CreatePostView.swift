import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var postText = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var shouldDismiss = false
    @State private var hateSpeechResult: HateSpeechResponse?
    @State private var isChecking = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Üst bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Gönderi Yayınla")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                .background(Color.black)
                
                // Ana içerik
                VStack(spacing: 20) {
                    TextEditor(text: $postText)
                        .frame(maxHeight: 200)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    if isChecking {
                        HStack {
                            Image(systemName: hateSpeechResult?.is_hate_speech == false ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(hateSpeechResult?.is_hate_speech == false ? .green : .red)
                            Text(hateSpeechResult?.is_hate_speech == false ? "İçerik uygundur" : "İçerik uygun değildir")
                                .foregroundColor(hateSpeechResult?.is_hate_speech == false ? .green : .red)
                        }
                        .padding(.horizontal)
                    }
                    
                    Text("\(postText.count)/500 karakter")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    // Test butonu
                    Button(action: {
                        postText = "Bu bir test gönderisidir. Nefret söylemi içermemektedir."
                    }) {
                        Text("Test Gönderisi 1")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        postText = "Bu bir nefret söylemi içeren test gönderisidir. @#$%&*!"
                    }) {
                        Text("Test Gönderisi 2")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Alt bilgi
                    Text("Lori'nin nefret söylemi ve dezenformasyon politikası")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                }
                
                // Paylaş butonu
                Button(action: { checkAndCreatePost() }) {
                    Text("Paylaş")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(postText.isEmpty || isLoading || (hateSpeechResult?.is_hate_speech == true) ? Color.gray : Color.white)
                        .cornerRadius(25)
                }
                .disabled(postText.isEmpty || isLoading || (hateSpeechResult?.is_hate_speech == true))
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .onChange(of: postText) { newValue in
            if !newValue.isEmpty {
                checkHateSpeech(text: newValue)
            } else {
                isChecking = false
                hateSpeechResult = nil
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("Tamam")) {
                    if shouldDismiss {
                        dismiss()
                    }
                }
            )
        }
    }
    
    private func checkHateSpeech(text: String) {
        isChecking = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let isHateSpeech = HateSpeechModel.shared.checkHateSpeech(text: text)
            
            DispatchQueue.main.async {
                isChecking = false
                hateSpeechResult = HateSpeechResponse(is_hate_speech: isHateSpeech)
                
                if isHateSpeech {
                    alertTitle = "Uyarı"
                    alertMessage = "Bu içerik nefret söylemi içeriyor. Lütfen içeriğinizi düzenleyin."
                    showAlert = true
                }
            }
        }
    }
    
    private func checkAndCreatePost() {
        guard !postText.isEmpty else { return }
        
        isLoading = true
        
        createPost()
    }
    
    private func createPost() {
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(currentUser.uid).getDocument { (document, error) in
            if let document = document,
               let username = document.data()?["username"] as? String,
               let interests = document.data()?["interests"] as? [String] {
                
                // Önce benzer içeriği kontrol et
                db.collection("posts")
                    .whereField("content", isEqualTo: postText)
                    .getDocuments { (snapshot, error) in
                        let similarPosts = snapshot?.documents ?? []
                        
                        let postData: [String: Any] = [
                            "username": username,
                            "content": postText,
                            "timestamp": FieldValue.serverTimestamp(),
                            "likes": 0,
                            "userId": currentUser.uid,
                            "tags": interests,
                            "isViewed": false,
                            "similarPosts": similarPosts.map { $0.documentID }
                        ]
                        
                        db.collection("posts").addDocument(data: postData) { error in
                            isLoading = false
                            
                            if let error = error {
                                alertTitle = "Hata"
                                alertMessage = "Gönderi paylaşılırken bir hata oluştu: \(error.localizedDescription)"
                                showAlert = true
                            } else {
                                alertTitle = "Başarılı"
                                alertMessage = "Gönderiniz başarıyla paylaşıldı!"
                                shouldDismiss = true
                                showAlert = true
                            }
                        }
                    }
            }
        }
    }
}

struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
    }
} 
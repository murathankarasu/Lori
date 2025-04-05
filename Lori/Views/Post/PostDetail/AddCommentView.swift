import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddCommentView: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var isLoading = false
    @State private var showHateSpeechAlert = false
    @State private var hateSpeechResponse: HateSpeechResponse?
    
    var body: some View {
        VStack(spacing: 16) {
            // Üst bar
            HStack {
                Button("İptal") {
                    dismiss()
                }
                .foregroundColor(.white)
                
                Spacer()
                
                Text("Yorum Yap")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: checkHateSpeechAndSubmit) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Gönder")
                            .foregroundColor(.white)
                    }
                }
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding()
            
            // Yorum alanı
            TextEditor(text: $commentText)
                .frame(height: 100)
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(.white)
                .padding(.horizontal)
        }
        .background(Color.black)
        .alert("Nefret Söylemi Tespit Edildi", isPresented: $showHateSpeechAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            if let response = hateSpeechResponse {
                Text("""
                    Kategori: \(response.data.category)
                    Güven Skoru: \(Int(response.data.confidence * 100))%
                    """)
            }
        }
    }
    
    private func checkHateSpeechAndSubmit() {
        let trimmedComment = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let response = try await HateSpeechService.shared.checkHateSpeech(text: trimmedComment)
                
                if response.data.isHateSpeech {
                    hateSpeechResponse = response
                    showHateSpeechAlert = true
                } else {
                    // Yorumu kaydet
                    let comment = Comment(
                        id: UUID().uuidString,
                        postId: post.id,
                        userId: Auth.auth().currentUser?.uid ?? "",
                        username: Auth.auth().currentUser?.displayName ?? "Anonim",
                        content: trimmedComment,
                        timestamp: Date()
                    )
                    
                    let db = Firestore.firestore()
                    try await db.collection("posts").document(post.id).updateData([
                        "comments": FieldValue.arrayUnion([[
                            "id": comment.id,
                            "userId": comment.userId,
                            "username": comment.username,
                            "content": comment.content,
                            "timestamp": comment.timestamp
                        ]])
                    ])
                    
                    dismiss()
                }
            } catch {
                print("Error checking hate speech: \(error)")
            }
            
            isLoading = false
        }
    }
} 

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddCommentView: View {
    let post: Post
    let onCommentAdded: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var isLoading = false
    @State private var showHateSpeechAlert = false
    @State private var hateSpeechResponse: APIResponse?
    
    private let db = Firestore.firestore()
    private let hateSpeechService = HateSpeechService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    TextEditor(text: $commentText)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(Color(.systemGray6).opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Yorum Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        checkHateSpeechAndSubmit()
                    } label: {
                        Text("Gönder")
                            .fontWeight(.medium)
                            .foregroundColor(!commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading ? .white : .gray)
                    }
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
            .alert("Uyarı", isPresented: $showHateSpeechAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                if let response = hateSpeechResponse {
                    Text("Bu yorumö nefret söylemi içeriyor olabilir.\nKategori: \(response.data.category)\nGüven Skoru: %\(Int(response.data.confidence * 100))")
                }
            }
        }
    }
    
    private func checkHateSpeechAndSubmit() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                let response = try await hateSpeechService.checkHateSpeech(text: commentText)
                
                await MainActor.run {
                    if response.data.isHateSpeech {
                        hateSpeechResponse = response
                        showHateSpeechAlert = true
                        isLoading = false
                    } else {
                        submitComment()
                    }
                }
            } catch {
                print("Nefret söylemi kontrolü sırasında hata: \(error.localizedDescription)")
                // Hata durumunda yorumu yine de gönder
                submitComment()
            }
        }
    }
    
    private func submitComment() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let commentId = UUID().uuidString
        let comment = Comment(
            id: commentId,
            postId: post.id,
            userId: userId,
            username: Auth.auth().currentUser?.displayName ?? "Anonim",
            content: commentText,
            timestamp: Date()
        )
        
        do {
            try db.collection("posts")
                .document(post.id)
                .collection("comments")
                .document(commentId)
                .setData(from: comment)
            
            onCommentAdded()
            dismiss()
        } catch {
            print("Yorum eklenirken hata oluştu: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}

struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                
                Text(comment.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(comment.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(comment.content)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
} 

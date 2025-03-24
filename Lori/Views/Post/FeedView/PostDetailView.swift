import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PostDetailView: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    @State private var newComment = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isDeleting = false
    
    private var isCurrentUser: Bool {
        Auth.auth().currentUser?.uid == post.userId
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Gönderi içeriği
                    VStack(alignment: .leading, spacing: 12) {
                        // Kullanıcı bilgileri
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading) {
                                Text(post.username)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(post.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if isCurrentUser {
                                Button(action: {
                                    isDeleting = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        // Gönderi metni
                        Text(post.content)
                            .font(.body)
                            .foregroundColor(.white)
                        
                        // Gönderi resmi (varsa)
                        if let imageUrl = post.imageUrl {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Yorumlar
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Yorumlar")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(post.comments) { comment in
                            CommentView(comment: comment)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .alert("Gönderiyi Sil", isPresented: $isDeleting) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    deletePost()
                }
            } message: {
                Text("Bu gönderiyi silmek istediğinizden emin misiniz?")
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func deletePost() {
        let db = Firestore.firestore()
        
        db.collection("posts").document(post.id).delete { error in
            if let error = error {
                errorMessage = "Gönderi silinirken bir hata oluştu: \(error.localizedDescription)"
                showError = true
                return
            }
            
            dismiss()
        }
    }
} 
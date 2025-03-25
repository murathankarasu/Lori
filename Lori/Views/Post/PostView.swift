import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PostView: View {
    let post: Post
    let isFollowing: Bool
    let onFollowTapped: (String) -> Void
    @State private var showComments = false
    @State private var isLiked = false
    @State private var likeCount: Int
    
    init(post: Post, isFollowing: Bool, onFollowTapped: @escaping (String) -> Void) {
        self.post = post
        self.isFollowing = isFollowing
        self.onFollowTapped = onFollowTapped
        _likeCount = State(initialValue: post.likes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Kullanıcı bilgileri
            HStack {
                AsyncImage(url: URL(string: "https://example.com/profile.jpg")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(post.username)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(post.timestamp.formatted())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if !isFollowing {
                    Button(action: { onFollowTapped(post.userId) }) {
                        Text("Takip Et")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                }
            }
            
            // Gönderi içeriği
            Text(post.content)
                .font(.body)
                .foregroundColor(.white)
                .padding(.vertical, 8)
            
            // Gönderi fotoğrafı
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
            
            // Etkileşim butonları
            HStack {
                Button(action: toggleLike) {
                    HStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .white)
                        Text("\(likeCount)")
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                Button(action: { showComments.toggle() }) {
                    HStack {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.white)
                        Text("\(post.comments.count)")
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Yorumlar
            if showComments {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(post.comments) { comment in
                        CommentView(comment: comment)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private func toggleLike() {
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1
        
        // Firebase'de beğeni sayısını güncelle
        let db = Firestore.firestore()
        db.collection("posts").document(post.id).updateData([
            "likes": likeCount
        ]) { error in
            if let error = error {
                print("Beğeni güncellenirken hata oluştu: \(error.localizedDescription)")
            }
        }
    }
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView(
            post: Post(
                id: "1",
                userId: "user1",
                username: "Test Kullanıcı",
                content: "Test gönderi içeriği",
                imageUrl: nil,
                timestamp: Date(),
                likes: 0,
                comments: [],
                isViewed: false,
                tags: []
            ),
            isFollowing: false,
            onFollowTapped: { _ in }
        )
        .preferredColorScheme(.dark)
    }
} 
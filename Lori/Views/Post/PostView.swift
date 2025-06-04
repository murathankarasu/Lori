import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

struct PostView: View {
    let post: Post
    let isFollowing: Bool
    let onFollowTapped: (String) -> Void
    @State private var showComments = false
    @State private var isLiked = false
    @State private var likeCount: Int
    @State private var disinformationCheck: DisinformationResponse?
    @State private var isCheckingDisinformation = false
    @State private var showDisinformationDetail = false
    
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
                if let profileImageUrl = post.profileImageUrl, !profileImageUrl.isEmpty, let url = URL(string: profileImageUrl) {
                    KFImage(url)
                        .setProcessor(RoundCornerImageProcessor(cornerRadius: 20))
                        .placeholder {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .retry(maxCount: 3, interval: .seconds(2))
                        .onFailure { error in
                            print("⚠️ Profile image loading failed: \(url) - Error: \(error.localizedDescription)")
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .onAppear {
                            print("📸 Trying to load profile image: \(url)")
                        }
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                }
                
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
            if let imageUrl = post.imageUrl, let url = URL(string: imageUrl) {
                KFImage(url)
                    .placeholder {
                        ZStack {
                            Color.gray.opacity(0.3)
                            ProgressView()
                                .tint(.white)
                        }
                        .frame(height: 350)
                        .cornerRadius(16)
                    }
                    .retry(maxCount: 3, interval: .seconds(2))
                    .onFailure { error in
                        print("⚠️ Image loading failed in PostView: \(url) - Error: \(error.localizedDescription)")
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 400)
                    .background(Color.black)
                    .cornerRadius(16)
                    .onAppear {
                        print("📸 Trying to load image in PostView: \(url)")
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
            
            if let check = disinformationCheck {
                Button(action: { showDisinformationDetail = true }) {
                    DisinformationCheckView(response: check)
                }
                .sheet(isPresented: $showDisinformationDetail) {
                    DisinformationCheckDetailView(response: check)
                }
            }
            
            if isCheckingDisinformation {
                ProgressView("Dezenformasyon kontrolü yapılıyor...")
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .onAppear {
            Task {
                do {
                    isCheckingDisinformation = true
                    disinformationCheck = try await DisinformationService().checkDisinformation(for: post)
                    isCheckingDisinformation = false
                } catch {
                    print("Dezenformasyon kontrolü yüklenirken hata oluştu: \(error)")
                    isCheckingDisinformation = false
                }
            }
        }
    }
    
    private func toggleLike() {
        // Unwrap post.id
        guard let postId = post.id else {
            print("❌ Post ID is nil in toggleLike.")
            return
        }
        
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1
        
        // Firebase'de beğeni sayısını güncelle
        let db = Firestore.firestore()
        db.collection("posts").document(postId).updateData([ // Use unwrapped postId
            "likes": likeCount
        ]) { error in
            if let error = error {
                print("Beğeni güncellenirken hata oluştu: \(error.localizedDescription)")
            }
        }
    }
}

struct DisinformationCheckView: View {
    let response: DisinformationResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if response.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 22))
                    Text("Verified Content")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        
                    Spacer()
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 22))
                    Text("Unverified Content")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        
                    Spacer()
                }
            }
            
            if response.isVerified {
                Text("This content has been verified by Lori's AI-powered fact-checking system in collaboration with trusted sources.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
            
            Text(response.explanation)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 4)
            
            if let sources = response.sources, !sources.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sources:")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ForEach(sources, id: \.self) { source in
                        Link(destination: URL(string: source)!) {
                            Text(source)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
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
                profileImageUrl: nil,
                timestamp: Date(),
                likes: 0,
                comments: [],
                tags: []
            ),
            isFollowing: false,
            onFollowTapped: { _ in }
        )
        .preferredColorScheme(.dark)
    }
} 

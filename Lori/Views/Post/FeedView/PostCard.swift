import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class PostCardViewModel: ObservableObject {
    @Published var isLiked: Bool = false
    @Published var likesCount: Int = 0
    @Published var commentsCount: Int = 0
    private let db = Firestore.firestore()
    private var likesListener: ListenerRegistration?
    private var commentsListener: ListenerRegistration?
    private let post: Post
    private let userId: String?
    
    init(post: Post) {
        self.post = post
        self.userId = Auth.auth().currentUser?.uid
        self.likesCount = post.likes
        listenToLikes()
        listenToComments()
        checkIfLiked()
    }
    
    deinit {
        likesListener?.remove()
        commentsListener?.remove()
    }
    
    func listenToLikes() {
        guard let postId = post.id else { return }
        likesListener = db.collection("posts").document(postId).collection("likes").addSnapshotListener { [weak self] snapshot, _ in
            self?.likesCount = snapshot?.documents.count ?? 0
        }
    }
    
    func listenToComments() {
        guard let postId = post.id else { return }
        commentsListener = db.collection("posts").document(postId).collection("comments").addSnapshotListener { [weak self] snapshot, _ in
            self?.commentsCount = snapshot?.documents.count ?? 0
        }
    }
    
    func checkIfLiked() {
        guard let postId = post.id, let userId = userId else { return }
        db.collection("posts").document(postId).collection("likes").document(userId).getDocument { [weak self] doc, _ in
            self?.isLiked = doc?.exists ?? false
        }
    }
    
    func toggleLike() {
        guard let postId = post.id, let userId = userId else { return }
        let likeRef = db.collection("posts").document(postId).collection("likes").document(userId)
        let postRef = db.collection("posts").document(postId)
        if isLiked {
            likeRef.delete()
            postRef.updateData(["likes": FieldValue.increment(Int64(-1))])
        } else {
            likeRef.setData([:])
            postRef.updateData(["likes": FieldValue.increment(Int64(1))])
        }
        isLiked.toggle()
    }
}

struct PostCard: View {
    let post: Post
    @StateObject private var viewModel: PostCardViewModel
    @State private var showComments = false
    
    init(post: Post) {
        self.post = post
        _viewModel = StateObject(wrappedValue: PostCardViewModel(post: post))
    }
    
    var body: some View {
        Button(action: {
            showComments = true
        }) {
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
                    
                    // Tag'leri göster
                    if !post.tags.isEmpty {
                        Text(post.tags.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                // Gönderi içeriği
                Text(post.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .multilineTextAlignment(.leading)
                
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
                
                // Etkileşim butonları
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.toggleLike()
                    }) {
                        HStack {
                            Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                                .foregroundColor(viewModel.isLiked ? .red : .white)
                            Text("\(viewModel.likesCount)")
                                .foregroundColor(.white)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.white)
                        Text("\(viewModel.commentsCount)")
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Paylaşım işlemi
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showComments) {
            PostDetailView(post: post)
        }
    }
} 
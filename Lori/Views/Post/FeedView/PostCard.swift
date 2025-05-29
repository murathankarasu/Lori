import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Kingfisher

class PostCardViewModel: ObservableObject {
    @Published var isLiked: Bool = false
    @Published var likesCount: Int = 0
    @Published var commentsCount: Int = 0
    private let db = Firestore.firestore()
    private var likesListener: ListenerRegistration?
    private var commentsListener: ListenerRegistration?
    private let post: Post
    private let userId: String?
    private let interactionService = InteractionService.shared
    
    init(post: Post) {
        self.post = post
        self.userId = Auth.auth().currentUser?.uid
        self.likesCount = post.likes
        setupListeners()
    }
    
    deinit {
        likesListener?.remove()
        commentsListener?.remove()
    }
    
    private func setupListeners() {
        guard let postId = post.id else { return }
        
        // Beğenileri dinle
        likesListener = interactionService.listenToLikes(for: postId) { [weak self] count, isLiked in
            self?.likesCount = count
            self?.isLiked = isLiked
        }
        
        // Yorumları dinle (sadece sayı için)
        commentsListener = db.collection("posts").document(postId).collection("comments").addSnapshotListener { [weak self] snapshot, _ in
            self?.commentsCount = snapshot?.documents.count ?? 0
        }
    }
    
    func toggleLike() {
        interactionService.toggleLike(for: post, isLiked: isLiked) { [weak self] newIsLiked, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Beğeni işlemi sırasında hata: \(error.localizedDescription)")
                return
            }
            
            // UI güncellemesi MainActor'da yapılacak
            Task { @MainActor in
                self.isLiked = newIsLiked
            }
        }
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
            VStack(alignment: .leading, spacing: 16) {
                // Kullanıcı bilgileri (farklı kullanıcıysa tıklanabilir, kendi postu için normal)
                if let currentUserId = Auth.auth().currentUser?.uid, post.userId != currentUserId {
                    HStack {
                        // PROFİL FOTOĞRAFI
                        if let profileImageUrl = post.profileImageUrl, !profileImageUrl.isEmpty, let url = URL(string: profileImageUrl) {
                            KFImage(url)
                                .placeholder {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.white)
                                }
                                .cacheMemoryOnly(false) // Hem bellek hem disk cache kullan
                                .fade(duration: 0.25) // Yumuşak geçiş efekti
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.username)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(post.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        if !post.tags.isEmpty {
                            Text(post.tags.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 16)
                } else {
                    HStack {
                        // PROFİL FOTOĞRAFI (KENDİ POSTU İÇİN)
                        if let profileImageUrl = post.profileImageUrl, !profileImageUrl.isEmpty, let url = URL(string: profileImageUrl) {
                            KFImage(url)
                                .placeholder {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.white)
                                }
                                .cacheMemoryOnly(false) // Hem bellek hem disk cache kullan
                                .fade(duration: 0.25) // Yumuşak geçiş efekti
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.username)
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(post.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        if !post.tags.isEmpty {
                            Text(post.tags.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Gönderi içeriği
                Text(post.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                
                // Gönderi resmi (varsa)
                if let imageUrl = post.imageUrl {
                    KFImage(URL(string: imageUrl))
                        .placeholder {
                            ZStack {
                                Color.gray.opacity(0.3)
                                ProgressView()
                                    .tint(.white)
                            }
                            .frame(height: 350)
                            .cornerRadius(16)
                        }
                        .cacheMemoryOnly(false)
                        .fade(duration: 0.3)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 400)
                        .background(Color.black)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                }
                
                // Etkileşim butonları
                HStack(spacing: 24) {
                    Button(action: {
                        viewModel.toggleLike()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                                .foregroundColor(viewModel.isLiked ? .red : .white)
                                .font(.system(size: 16, weight: .medium))
                            Text("\(viewModel.likesCount)")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                        Text("\(viewModel.commentsCount)")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Paylaşım işlemi
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray6), lineWidth: 1)
                    .background(Color.black)
            )
            .cornerRadius(16)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showComments) {
            PostDetailView(post: post)
        }
    }
} 

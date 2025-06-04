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
    @State private var isPressed = false
    @State private var likeAnimation = false
    @State private var heartPulse = false
    
    init(post: Post) {
        self.post = post
        _viewModel = StateObject(wrappedValue: PostCardViewModel(post: post))
    }
    
    var body: some View {
        Button(action: {
            showComments = true
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Kullanıcı bilgileri ve gönderi içeriği
                HStack(alignment: .top, spacing: 12) {
                    // Profil fotoğrafı - Geliştirilmiş
                    if let profileImageUrl = post.profileImageUrl, !profileImageUrl.isEmpty, let url = URL(string: profileImageUrl) {
                        KFImage(url)
                            .placeholder {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .font(.system(size: 20))
                                }
                                .frame(width: 48, height: 48)
                            }
                            .cacheMemoryOnly(false)
                            .fade(duration: 0.25)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.white.opacity(0.1), Color.clear]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    } else {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 20))
                        }
                        .frame(width: 48, height: 48)
                    }
                    
                    // İçerik alanı
                    VStack(alignment: .leading, spacing: 10) {
                        // Kullanıcı adı ve zaman bilgisi - Geliştirilmiş
                        HStack(spacing: 8) {
                            Text(post.username)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.white, Color.white.opacity(0.9)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("·")
                                .foregroundColor(.gray.opacity(0.7))
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(post.relativeTimeString)
                                .font(.system(size: 15))
                                .foregroundColor(.gray.opacity(0.8))
                            
                            Spacer()
                            
                            if !post.tags.isEmpty {
                                HStack(spacing: 4) {
                                    ForEach(post.tags.prefix(2), id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(Color.white.opacity(0.1))
                                                    .overlay(
                                                        Capsule()
                                                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                                    )
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Gönderi içeriği - Geliştirilmiş typography
                        Text(post.content)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .lineSpacing(2)
                        
                        // Gönderi resmi (varsa) - Geliştirilmiş
                        if let imageUrl = post.imageUrl {
                            KFImage(URL(string: imageUrl))
                                .placeholder {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(LinearGradient(
                                                gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                        ProgressView()
                                            .scaleEffect(1.2)
                                            .tint(.white.opacity(0.7))
                                    }
                                    .frame(height: 300)
                                }
                                .cacheMemoryOnly(false)
                                .fade(duration: 0.3)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 350)
                                .background(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.white.opacity(0.1), Color.clear]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.5
                                        )
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        // Etkileşim butonları - Modern tasarım
                        HStack(spacing: 40) {
                            // Yorum butonu
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    showComments = true
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bubble.right")
                                        .foregroundColor(.gray.opacity(0.8))
                                        .font(.system(size: 18, weight: .medium))
                                    Text("\(viewModel.commentsCount)")
                                        .foregroundColor(.gray.opacity(0.9))
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.03))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                                        )
                                )
                            }
                            .buttonStyle(SpringButtonStyle())
                            
                            // Beğeni butonu - Geliştirilmiş animasyon
                            Button(action: {
                                // Beğeni animasyonu
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                    likeAnimation.toggle()
                                }
                                
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    heartPulse = true
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        heartPulse = false
                                    }
                                }
                                
                                viewModel.toggleLike()
                            }) {
                                HStack(spacing: 8) {
                                    ZStack {
                                        // Arkada kalp patlaması efekti
                                        if viewModel.isLiked && likeAnimation {
                                            Image(systemName: "heart.fill")
                                                .foregroundColor(.red.opacity(0.3))
                                                .font(.system(size: 25, weight: .medium))
                                                .scaleEffect(heartPulse ? 1.8 : 1.4)
                                                .opacity(heartPulse ? 0 : 0.6)
                                        }
                                        
                                        // Ana kalp ikonu
                                        Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                                            .foregroundColor(viewModel.isLiked ? .red : .gray.opacity(0.8))
                                            .font(.system(size: 18, weight: .medium))
                                            .scaleEffect(heartPulse ? 1.3 : (viewModel.isLiked ? 1.1 : 1.0))
                                            .rotationEffect(.degrees(likeAnimation ? 360 : 0))
                                    }
                                    
                                    Text("\(viewModel.likesCount)")
                                        .foregroundColor(viewModel.isLiked ? .red.opacity(0.9) : .gray.opacity(0.9))
                                        .font(.system(size: 15, weight: .medium))
                                        .scaleEffect(heartPulse ? 1.1 : 1.0)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(viewModel.isLiked ? Color.red.opacity(0.1) : Color.white.opacity(0.03))
                                        .overlay(
                                            Capsule()
                                                .stroke(viewModel.isLiked ? Color.red.opacity(0.2) : Color.white.opacity(0.05), lineWidth: 0.5)
                                        )
                                        .scaleEffect(heartPulse ? 1.05 : 1.0)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                        .padding(.top, 12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                // Alt çizgi - Daha subtle
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.gray.opacity(0.2), Color.clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .fullScreenCover(isPresented: $showComments) {
            PostDetailView(post: post)
        }
    }
}

// Modern buton animasyonu için custom style
struct SpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
} 

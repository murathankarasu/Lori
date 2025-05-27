import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Kingfisher

// MARK: - ProfileView
struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    let userId: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var showEditProfile = false
    @State private var selectedPost: Post?
    @State private var showPostDetail = false
    @State private var showSettings = false
    @State private var showSearchSheet = false
    @State private var showDirectMessage = false
    let fromChatView: Bool
    
    init(userId: String, fromChatView: Bool = false) {
        self.userId = userId
        self.fromChatView = fromChatView
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profil Fotoğrafı ve Topluluk Rozeti
                    ZStack(alignment: .bottomTrailing) {
                        if let imageUrl = viewModel.profileImageUrl {
                            KFImage(URL(string: imageUrl))
                                .cacheMemoryOnly(false)
                                .cacheOriginalImage()
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray)
                        }
                        // Topluluk Rozeti
                        if viewModel.hasCommunityBadge {
                            CommunityBadgeView()
                                .offset(x: 12, y: 12)
                        }
                    }
                    
                    // Kullanıcı Adı
                    Text(viewModel.username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Biyografi
                    if !viewModel.bio.isEmpty {
                        Text(viewModel.bio)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Profili Düzenle Butonu - Sadece mevcut kullanıcı için
                    if viewModel.isCurrentUser {
                        Button(action: { showEditProfile = true }) {
                            Text("Edit Profile")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                    } else {
                        // Takip Et/Takibi Bırak Butonu
                        Button(action: { Task { await viewModel.toggleFollow() } }) {
                            Text(viewModel.isFollowing ? "Unfollow" : "Follow")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(viewModel.isFollowing ? .white : .black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(viewModel.isFollowing ? Color.gray : Color.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    // İstatistikler
                    HStack(spacing: 40) {
                        // Gönderi Sayısı
                        Button(action: {}) {
                            VStack {
                                Text("\(viewModel.posts.count)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Posts")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Takipçi Sayısı
                        NavigationLink(destination: FollowersView(userId: viewModel.userId)) {
                            VStack {
                                Text("\(viewModel.followersCount)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Takip Edilen Sayısı
                        NavigationLink(destination: FollowingView(userId: viewModel.userId)) {
                            VStack {
                                Text("\(viewModel.followingCount)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    // İlgi Alanları
                    if !viewModel.interests.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Gönderiler
                    PostsGridView(
                        isLoading: viewModel.isLoading,
                        posts: viewModel.posts,
                        selectedPost: $selectedPost,
                        showPostDetail: $showPostDetail,
                        onScrolledAtBottom: {
                            Task {
                                await viewModel.fetchMoreUserPosts()
                            }
                        },
                        hasMorePosts: viewModel.hasMorePosts
                    )
                }
                .padding(.top, 60)
            }
            
            // Ekranın üst kısmındaki butonlar (sabit header)
            VStack(spacing: 0) {
                HStack {
                    // Özel durum: Chat ekranından gelmişse, sadece tek bir geri butonu göster
                    if fromChatView {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 16)
                    }
                    // Normal durum: Arama Butonu (sadece kendi profilindeyse)
                    else if viewModel.isCurrentUser {
                        Button(action: {
                            showSearchSheet.toggle()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 16)
                        .fullScreenCover(isPresented: $showSearchSheet) {
                            SearchView()
                        }
                    }
                    // Normal durum: Geri Dönüş Butonu (sadece başka bir kullanıcının profilindeyse)
                    else if !viewModel.isCurrentUser {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 16)
                    } else {
                        Spacer().frame(width: 60)
                    }

                    Spacer()

                    // Ayarlar Butonu (sadece kendi profilindeyse) veya Mesaj Butonu (başka profildeyse)
                    if viewModel.isCurrentUser {
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                    } else {
                        // Mesaj Butonu (başka kullanıcının profilindeyse)
                        Button(action: { 
                            // Direk mesaj ekranına geçmek için showDirectMessage değişkenini true yapalım
                            showDirectMessage = true 
                        }) {
                            Image(systemName: "message")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 44)
                .padding(.bottom, 8)
                .background(Color.black)

                Spacer()
            }
            .ignoresSafeArea(edges: .top)
            .zIndex(1)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showEditProfile) {
            NavigationView {
                EditProfileView(
                    username: $viewModel.username,
                    bio: $viewModel.bio,
                    interests: $viewModel.interests,
                    profileImageUrl: $viewModel.profileImageUrl
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationView {
                SettingsView(isLoggedIn: .constant(true))
            }
        }
        .fullScreenCover(isPresented: $showDirectMessage) {
            if let currentUserId = Auth.auth().currentUser?.uid {
                DirectMessageWithUserView(currentUserId: currentUserId, targetUserId: userId)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            // Sayfa her görüntülendiğinde verileri yenile
            Task {
                await viewModel.fetchUserProfile()
                await viewModel.fetchUserPosts()
            }
        }
        .fullScreenCover(isPresented: $showPostDetail) {
            if let post = selectedPost {
                PostDetailView(post: post)
            }
        }
    }
}

// Başlangıçta belirli bir kullanıcıyla sohbet başlatacak görünüm
struct DirectMessageWithUserView: View {
    let currentUserId: String
    let targetUserId: String
    @StateObject private var viewModel: DirectMessageViewModel
    @State private var conversationId: String? = nil
    @State private var isCreatingConversation = false
    @State private var shouldShowChat = false
    @Environment(\.dismiss) private var dismiss
    
    init(currentUserId: String, targetUserId: String) {
        self.currentUserId = currentUserId
        self.targetUserId = targetUserId
        self._viewModel = StateObject(wrappedValue: DirectMessageViewModel(userId: currentUserId))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if isCreatingConversation || !shouldShowChat {
                    ChatBubbleLoadingAnimation()
                        .onAppear {
                            // Animasyonun tamamlanmasını bekle, sonra sohbeti göster
                            if conversationId != nil && !shouldShowChat {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                                    shouldShowChat = true
                                }
                            }
                        }
                } else if conversationId != nil {
                    // Konuşma hazır olduğunda doğrudan ChatView'ı göster
                    ChatViewWithBackButton(conversationId: conversationId!, viewModel: viewModel, onBackTapped: {
                        // Profil ekranını kapatıp Featured ekranına dönüş
                        dismiss()
                    })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Kapat")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            startOrOpenConversation()
        }
    }
    
    private func startOrOpenConversation() {
        isCreatingConversation = true
        
        // İlk olarak mevcut konuşmaları yükle
        Task {
            await viewModel.loadConversations()
            
            // Kullanıcıyla mevcut bir konuşma var mı kontrol et
            if let existingConversation = viewModel.conversations.first(where: { conversation in
                conversation.users.contains(targetUserId) && conversation.users.contains(currentUserId)
            }) {
                // Mevcut konuşmayı aç
                if let conversationId = existingConversation.id {
                    await viewModel.loadMessages(for: conversationId)
                    
                    DispatchQueue.main.async {
                        self.conversationId = conversationId
                        self.isCreatingConversation = false
                        
                        // Animasyonun tamamlanmasını bekle, en az 4.5 saniye göster
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                            self.shouldShowChat = true
                        }
                    }
                }
            } else {
                // Yeni konuşma başlat
                let initialMessage = "Merhaba"
                let newConversationId = await viewModel.startNewConversation(with: targetUserId, initialMessage: initialMessage)
                
                if let conversationId = newConversationId {
                    await viewModel.loadMessages(for: conversationId)
                    
                    DispatchQueue.main.async {
                        self.conversationId = conversationId
                        self.isCreatingConversation = false
                        
                        // Animasyonun tamamlanmasını bekle, en az 4.5 saniye göster
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                            self.shouldShowChat = true
                        }
                    }
                } else {
                    // Hata durumu
                    DispatchQueue.main.async {
                        isCreatingConversation = false
                    }
                }
            }
        }
    }
}

// ChatView'ı saran ve geri butonuna özel davranış ekleyen bir view
struct ChatViewWithBackButton: View {
    let conversationId: String
    @ObservedObject var viewModel: DirectMessageViewModel
    let onBackTapped: () -> Void
    @State private var showingProfile = false
    @State private var isNotificationsMuted = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Özel başlık - geri butonu tıklandığında sohbet listesine gider
                HStack(spacing: 16) {
                    Button(action: {
                        onBackTapped()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Profil fotoğrafı ve kullanıcı adı - Tıklanabilir
                    Button(action: {
                        if otherUserId != nil {
                            showingProfile = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            // Profil fotoğrafı ve kullanıcı adı - Aynı ChatView'daki gibi
                            if let otherUser = otherUser, let profileImageUrl = otherUser.profileImageUrl, !profileImageUrl.isEmpty {
                                KFImage(URL(string: profileImageUrl))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                                                          .frame(width: 36, height: 36)
                                      .overlay(
                                         Text(otherUserName)
                                              .font(.system(size: 16, weight: .semibold))
                                              .foregroundColor(.white)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(otherUserName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Aktif")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Menü butonu
                    Menu {
                        Button(action: {
                            isNotificationsMuted.toggle()
                        }) {
                            if isNotificationsMuted {
                                Label("Bildirimleri Aç", systemImage: "bell")
                            } else {
                                Label("Sessize Al", systemImage: "bell.slash")
                            }
                        }
                        
                        Button(action: {
                            if otherUserId != nil {
                                showingProfile = true
                            }
                        }) {
                            Label("Profili Görüntüle", systemImage: "person.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            // Konuşmayı silme onayını göster
                            showingDeleteConfirmation = true
                        }) {
                            Label("Sohbeti Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black)
                
                // ChatView içeriği
                ChatView(conversationId: conversationId, viewModel: viewModel, hideHeader: true)
            }
        }
        // Profil Görüntüleme
        .fullScreenCover(isPresented: $showingProfile) {
            if let userId = otherUserId {
                ProfileView(userId: userId, fromChatView: true)
            }
        }
        // Sohbeti silme onayı
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Sohbeti Sil"),
                message: Text("Bu sohbeti silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
                primaryButton: .destructive(Text("Sil")) {
                    deleteConversation()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // Konuşmayı sil
    private func deleteConversation() {
        Task {
            await viewModel.deleteConversation(conversationId)
            // Silme işleminden sonra geri dön
            onBackTapped()
        }
    }
    
    // Diğer kullanıcının bilgileri - ChatView'dan kopyalandı
    private var otherUser: User? {
        guard let conversation = viewModel.conversations.first(where: { $0.id == conversationId }),
              let otherUserId = conversation.users.first(where: { $0 != viewModel.userId }) else {
            return nil
        }
        return viewModel.userCache[otherUserId]
    }
    
    private var otherUserId: String? {
        guard let conversation = viewModel.conversations.first(where: { $0.id == conversationId }) else {
            return nil
        }
        return conversation.users.first(where: { $0 != viewModel.userId })
    }
    
    private var otherUserName: String {
        return otherUser?.username ?? "Kullanıcı"
    }
}

struct CommunityBadgeView: View {
    @State private var showFullScreenAnimation = false
    var body: some View {
        ZStack {
            Button(action: { showFullScreenAnimation.toggle() }) {
                Image("badge")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .shadow(radius: 4)
            }
            .fullScreenCover(isPresented: $showFullScreenAnimation) {
                CommunityBadgeAnimationView()
            }
        }
    }
}

// Sohbet baloncukları yükselen animasyon 
struct ChatBubbleLoadingAnimation: View {
    @State private var bubbleScale1: CGFloat = 0.1
    @State private var bubbleScale2: CGFloat = 0.1
    @State private var bubbleScale3: CGFloat = 0.1
    @State private var bubbleOpacity1: Double = 0
    @State private var bubbleOpacity2: Double = 0
    @State private var bubbleOpacity3: Double = 0
    @State private var bubbleOffset1: CGFloat = 0
    @State private var bubbleOffset2: CGFloat = 0
    @State private var bubbleOffset3: CGFloat = 0
    @State private var horizontalOffset1: CGFloat = 0
    @State private var horizontalOffset2: CGFloat = 0
    @State private var horizontalOffset3: CGFloat = 0
    @State private var rotation1: Double = -5
    @State private var rotation2: Double = 5
    @State private var rotation3: Double = -5
    @State private var isAnimating = false
    @State private var animationCount = 0
    
    // Toplam animasyon süresi (saniye)
    let totalAnimationDuration: Double = 4.0
    
    let bubble1Delay = 0.0
    let bubble2Delay = 0.7
    let bubble3Delay = 1.4
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                // Sohbet baloncukları
                VStack {
                    HStack(spacing: 20) {
                        // Sol baloncuk (gelen mesaj)
                        LoadingBubbleShape(isFromCurrentUser: false)
                            .fill(Color.gray.opacity(0.7))
                            .frame(width: 60, height: 40)
                            .scaleEffect(bubbleScale1)
                            .opacity(bubbleOpacity1)
                            .offset(x: horizontalOffset1, y: bubbleOffset1)
                            .rotationEffect(.degrees(rotation1))
                            .blur(radius: bubbleOpacity1 * 2)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    HStack(spacing: 20) {
                        Spacer()
                        
                        // Sağ baloncuk (giden mesaj)
                        LoadingBubbleShape(isFromCurrentUser: true)
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 70, height: 45)
                            .scaleEffect(bubbleScale2)
                            .opacity(bubbleOpacity2)
                            .offset(x: horizontalOffset2, y: bubbleOffset2)
                            .rotationEffect(.degrees(rotation2))
                            .blur(radius: bubbleOpacity2 * 2)
                    }
                    .padding(.vertical, 10)
                    
                    HStack(spacing: 20) {
                        // Sol baloncuk (gelen mesaj)
                        LoadingBubbleShape(isFromCurrentUser: false)
                            .fill(Color.gray.opacity(0.7))
                            .frame(width: 80, height: 50)
                            .scaleEffect(bubbleScale3)
                            .opacity(bubbleOpacity3)
                            .offset(x: horizontalOffset3, y: bubbleOffset3)
                            .rotationEffect(.degrees(rotation3))
                            .blur(radius: bubbleOpacity3 * 2)
                        
                        Spacer()
                    }
                }
            }
            .frame(height: 200)
            
            Text("Sohbetiniz Hazırlanıyor")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .opacity(isAnimating ? 1 : 0.7)
                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // İlk baloncuk animasyonu
        withAnimation(Animation.easeOut(duration: 2.0).delay(bubble1Delay).repeatForever(autoreverses: false)) {
            bubbleScale1 = 1.0
            bubbleOpacity1 = 0.8
            bubbleOffset1 = -100
            horizontalOffset1 = 10
            rotation1 = 5
        }
        
        withAnimation(Animation.easeOut(duration: 2.5).delay(bubble1Delay + 1.3).repeatForever(autoreverses: false)) {
            bubbleOpacity1 = 0
            horizontalOffset1 = 20
        }
        
        // İkinci baloncuk animasyonu
        withAnimation(Animation.easeOut(duration: 2.0).delay(bubble2Delay).repeatForever(autoreverses: false)) {
            bubbleScale2 = 1.0
            bubbleOpacity2 = 0.8
            bubbleOffset2 = -100
            horizontalOffset2 = -15
            rotation2 = -8
        }
        
        withAnimation(Animation.easeOut(duration: 2.5).delay(bubble2Delay + 1.3).repeatForever(autoreverses: false)) {
            bubbleOpacity2 = 0
            horizontalOffset2 = -25
        }
        
        // Üçüncü baloncuk animasyonu
        withAnimation(Animation.easeOut(duration: 2.0).delay(bubble3Delay).repeatForever(autoreverses: false)) {
            bubbleScale3 = 1.0
            bubbleOpacity3 = 0.8
            bubbleOffset3 = -100
            horizontalOffset3 = 15
            rotation3 = 8
        }
        
        withAnimation(Animation.easeOut(duration: 2.5).delay(bubble3Delay + 1.3).repeatForever(autoreverses: false)) {
            bubbleOpacity3 = 0
            horizontalOffset3 = 30
        }
    }
}

// Mesaj baloncuğu şekli - Animasyon için özel tasarım
struct LoadingBubbleShape: Shape {
    var isFromCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, 
                                cornerRadius: 15)
        
        let cornerPoint = isFromCurrentUser 
            ? CGPoint(x: rect.maxX, y: rect.minY) 
            : CGPoint(x: rect.minX, y: rect.minY)
        
        let trianglePath = UIBezierPath()
        trianglePath.move(to: cornerPoint)
        
        if isFromCurrentUser {
            trianglePath.addLine(to: CGPoint(x: rect.maxX + 8, y: rect.minY - 5))
            trianglePath.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.minY + 8))
        } else {
            trianglePath.addLine(to: CGPoint(x: rect.minX - 8, y: rect.minY - 5))
            trianglePath.addLine(to: CGPoint(x: rect.minX + 5, y: rect.minY + 8))
        }
        
        trianglePath.close()
        path.append(trianglePath)
        
        return Path(path.cgPath)
    }
}

#Preview {
    ProfileView(userId: "PREVIEW_USER_ID", fromChatView: false)
} 

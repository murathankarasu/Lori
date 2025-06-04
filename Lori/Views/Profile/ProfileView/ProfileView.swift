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
    
    @State private var selectedPost: Post?
    @State private var showPostDetail = false
    @State private var showDirectMessage = false
    @State private var showNotificationCenter = false
    let fromChatView: Bool
    // Binding to the root authentication state so that SettingsView can update it on sign-out
    private var isLoggedIn: Binding<Bool>
    
    init(userId: String, fromChatView: Bool = false, isLoggedIn: Binding<Bool> = .constant(true)) {
        self.userId = userId
        self.fromChatView = fromChatView
        self.isLoggedIn = isLoggedIn
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
                        NavigationLink(destination: EditProfileView(
                            username: $viewModel.username,
                            bio: $viewModel.bio,
                            profileImageUrl: $viewModel.profileImageUrl
                        )) {
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
                        // Kendi profilimizde - sol üstte notification badge
                        NotificationBadgeView {
                            showNotificationCenter = true
                        }
                        .padding(.leading, 16)
                    }

                    Spacer()

                    // Ayarlar Butonu (sadece kendi profilindeyse) veya Mesaj Butonu (başka profildeyse)
                    if viewModel.isCurrentUser {
                        // Pass the binding so that SettingsView can mutate the authentication state
                        NavigationLink(destination: SettingsView(isLoggedIn: isLoggedIn)) {
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
        .fullScreenCover(isPresented: $showDirectMessage) {
            if let currentUserId = Auth.auth().currentUser?.uid {
                DirectMessageWithUserView(currentUserId: currentUserId, targetUserId: userId)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .fullScreenCover(isPresented: $showNotificationCenter) {
            NotificationCenterView()
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

#Preview {
    ProfileView(userId: "PREVIEW_USER_ID", fromChatView: false)
} 

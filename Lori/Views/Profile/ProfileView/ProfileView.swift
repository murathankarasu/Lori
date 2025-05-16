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
    
    init(userId: String) {
        self.userId = userId
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
                            Text("Profili Düzenle")
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
                            Text(viewModel.isFollowing ? "Takibi Bırak" : "Takip Et")
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
                                Text("Gönderi")
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
                                Text("Takipçi")
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
                                Text("Takip")
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
                    // Arama Butonu (sadece kendi profilindeyse)
                    if viewModel.isCurrentUser {
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
                        .sheet(isPresented: $showSearchSheet) {
                            SearchView()
                        }
                    }
                    // Geri Dönüş Butonu (sadece başka bir kullanıcının profilindeyse)
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

                    // Ayarlar Butonu (sadece kendi profilindeyse)
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
                        Spacer().frame(width: 60)
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
    @State private var showInfo = false
    var body: some View {
        ZStack {
            Button(action: { showInfo.toggle() }) {
                Image("badge")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .shadow(radius: 4)
            }
            .sheet(isPresented: $showInfo) {
                VStack(spacing: 24) {
                    Capsule()
                        .frame(width: 40, height: 5)
                        .foregroundColor(.gray.opacity(0.4))
                        .padding(.top, 12)
                    Image("badge")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .padding(.top, 8)
                    Text("Community Badge")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("This badge is given to users who make a positive contribution to the Lori community by receiving positive interactions on their posts.")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color.black.ignoresSafeArea())
            }
        }
    }
}

#Preview {
    ProfileView(userId: "PREVIEW_USER_ID")
} 

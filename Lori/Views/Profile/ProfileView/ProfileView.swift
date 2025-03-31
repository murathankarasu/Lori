import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Kingfisher

// MARK: - ProfileView
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showFollowers = false
    @State private var showFollowing = false
    @State private var selectedPost: Post?
    @State private var showPostDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profil Fotoğrafı
                        if let imageUrl = viewModel.profileImageUrl {
                            KFImage(URL(string: imageUrl))
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
                        
                        // Profili Düzenle Butonu
                        Button(action: { showEditProfile = true }) {
                            Text("Profili Düzenle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
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
                            Button(action: { showFollowers = true }) {
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
                            Button(action: { showFollowing = true }) {
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
                            showPostDetail: $showPostDetail
                        )
                    }
                    .padding(.top, 32)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
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
            .sheet(isPresented: $showFollowers) {
                NavigationView {
                    FollowersView(userId: viewModel.userId)
                }
            }
            .sheet(isPresented: $showFollowing) {
                NavigationView {
                    FollowingView(userId: viewModel.userId)
                }
            }
            .sheet(isPresented: $showPostDetail) {
                if let post = selectedPost {
                    NavigationView {
                        PostDetailView(post: post)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchUserProfile()
            await viewModel.fetchUserPosts()
        }
    }
}

#Preview {
    ProfileView()
} 

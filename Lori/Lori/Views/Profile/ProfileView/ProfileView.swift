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
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
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
                        showPostDetail: $showPostDetail
                    )
                }
                .padding(.top, 32)
            }
            
            // Geri Dönüş Butonu
            if !viewModel.isCurrentUser {
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 16)
                        .padding(.top, 16)
                        Spacer()
                    }
                    Spacer()
                }
            }
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
    }
}

#Preview {
    ProfileView(userId: "PREVIEW_USER_ID")
} 

import SwiftUI
import FirebaseFirestore
import Kingfisher
import FirebaseAuth

struct FollowingView: View {
    @StateObject private var viewModel: FollowingViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: FollowingViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if viewModel.following.isEmpty {
                 Text("Not following anyone yet")
                    .foregroundColor(.gray)
            } else {
                List {
                    // Takip edilen kullanıcılar için ForEach
                    ForEach(viewModel.following) { user in
                        FollowingRow(user: user, viewModel: viewModel) // FollowingRow kullan
                    }
                    .listRowBackground(Color.black)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Following")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// Takip edilen kullanıcı satırı için ayrı view
struct FollowingRow: View {
    let user: User
    @ObservedObject var viewModel: FollowingViewModel
    private var currentUserId: String? = Auth.auth().currentUser?.uid
    
    init(user: User, viewModel: FollowingViewModel) {
        self.user = user
        self.viewModel = viewModel
    }
    
    var body: some View {
        HStack {
            // Kullanıcı bilgisi bölümü
            let userInfoView = HStack {
                KFImage(URL(string: user.profileImageUrl ?? ""))
                    .cacheMemoryOnly(false)
                    .cacheOriginalImage()
                    .placeholder {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 45, height: 45)
                            .foregroundColor(.gray)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                
                VStack(alignment: .leading) {
                    Text(user.username)
                        .font(.headline)
                        .foregroundColor(.white)
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }

            // Eğer satırdaki kullanıcı mevcut kullanıcı DEĞİLSE NavigationLink göster
             if user.id != currentUserId {
                NavigationLink(destination: ProfileView(userId: user.id)) {
                    userInfoView
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                 // Eğer satırdaki kullanıcı mevcut kullanıcı İSE NavigationLink olmadan göster
                userInfoView
            }

            Spacer()
            
            // Takip Et/Bırak butonu
            if user.id != currentUserId {
                let isFollowing = viewModel.followStatus[user.id] ?? false
                Button(action: { Task { await viewModel.toggleFollow(userToToggle: user) } }) {
                    Text(isFollowing ? "Unfollow" : "Follow")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isFollowing ? .white : .black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isFollowing ? Color.gray.opacity(0.7) : Color.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
} 

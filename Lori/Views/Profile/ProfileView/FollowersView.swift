import SwiftUI
import FirebaseFirestore
import Kingfisher
import FirebaseAuth

struct FollowersView: View {
    @StateObject private var viewModel: FollowersViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: FollowersViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else if viewModel.followers.isEmpty {
                Text("No followers yet")
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(viewModel.followers) { user in
                        FollowerRow(user: user, viewModel: viewModel)
                    }
                    .listRowBackground(Color.black)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Followers")
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

struct FollowerRow: View {
    let user: User
    @ObservedObject var viewModel: FollowersViewModel
    private var currentUserId: String? = Auth.auth().currentUser?.uid
    
    init(user: User, viewModel: FollowersViewModel) {
        self.user = user
        self.viewModel = viewModel
    }
    
    var body: some View {
        HStack {
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

            if user.id != currentUserId {
                NavigationLink(destination: ProfileView(userId: user.id)) {
                   userInfoView
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                userInfoView
            }

            Spacer()
            
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

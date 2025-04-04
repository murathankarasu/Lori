import SwiftUI
import Kingfisher

struct PostsGridView: View {
    let isLoading: Bool
    let posts: [Post]
    @Binding var selectedPost: Post?
    @Binding var showPostDetail: Bool
    
    private var limitedPosts: [Post] {
        Array(posts.prefix(2))
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if posts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Henüz gönderi yok")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    Text("İlk gönderini paylaşmak için + butonuna tıkla")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(limitedPosts) { post in
                            PostCard(post: post)
                                .onTapGesture {
                                    selectedPost = post
                                    showPostDetail = true
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
}

struct ProfileGridItem: View {
    let post: Post
    
    var body: some View {
        ZStack {
            if let imageUrl = post.imageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
                Text(post.content)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .padding(8)
            }
        }
        .frame(height: UIScreen.main.bounds.width / 2)
        .clipped()
        .cornerRadius(12)
    }
}

struct ProfileActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
} 
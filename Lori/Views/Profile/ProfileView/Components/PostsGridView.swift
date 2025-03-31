import SwiftUI
import Kingfisher

struct PostsGridView: View {
    let isLoading: Bool
    let posts: [Post]
    @Binding var selectedPost: Post?
    @Binding var showPostDetail: Bool
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
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
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(posts) { post in
                        ProfileGridItem(post: post)
                            .onTapGesture {
                                selectedPost = post
                                showPostDetail = true
                            }
                    }
                }
                .padding(.horizontal, 2)
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
    }
} 
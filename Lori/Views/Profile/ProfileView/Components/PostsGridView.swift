import SwiftUI
import Kingfisher

struct PostsGridView: View {
    let isLoading: Bool
    let posts: [Post]
    @Binding var selectedPost: Post?
    @Binding var showPostDetail: Bool
    var onScrolledAtBottom: (() -> Void)? = nil
    var hasMorePosts: Bool = true
    
    var body: some View {
        Group {
            if isLoading && posts.isEmpty {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if posts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No posts yet")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    Text("Tap the + button to share your first post!")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(posts.indices, id: \.self) { index in
                            let post = posts[index]
                            PostCard(post: post)
                                .onTapGesture {
                                    selectedPost = post
                                    showPostDetail = true
                                }
                                .onAppear {
                                    if index == posts.count - 1 {
                                        onScrolledAtBottom?()
                                    }
                                }
                        }
                        if isLoading && posts.count > 0 {
                            ProgressView()
                                .tint(.white)
                                .padding()
                        }
                        if !hasMorePosts && posts.count > 0 {
                            Text("No more posts to show.")
                                .foregroundColor(.gray)
                                .padding(.bottom, 16)
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
            if let imageUrl = post.imageUrl, let url = URL(string: imageUrl) {
                KFImage(url)
                    .placeholder {
                        ZStack {
                            Color.gray.opacity(0.3)
                            ProgressView()
                                .tint(.white)
                        }
                        .cornerRadius(16)
                    }
                    .retry(maxCount: 3, interval: .seconds(2))
                    .onFailure { error in
                        print("⚠️ Image loading failed in ProfileGridItem: \(url) - Error: \(error.localizedDescription)")
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 350)
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(16)
                    .onAppear {
                        print("📸 Trying to load image in ProfileGridItem: \(url)")
                    }
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
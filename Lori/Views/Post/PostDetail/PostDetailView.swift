import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PostDetailView: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PostDetailViewModel()
    @State private var showDeleteAlert = false
    @State private var showCommentSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        PostHeaderView(post: post)
                            .padding(.horizontal)
                        
                        PostContentView(post: post)
                            .padding(.horizontal)
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.horizontal)
                        
                        PostActionsView(
                            post: post,
                            isLiked: viewModel.isLiked,
                            likesCount: viewModel.likesCount,
                            commentsCount: viewModel.comments.count,
                            onLikeTapped: viewModel.toggleLike,
                            onCommentTapped: { showCommentSheet = true }
                        )
                        .padding(.horizontal)
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.horizontal)
                        
                        CommentsListView(comments: viewModel.comments)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                }
                
                if post.userId == Auth.auth().currentUser?.uid {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .imageScale(.large)
                        }
                    }
                }
            }
        }
        .alert("Gönderiyi Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) { }
                .foregroundColor(.white)
            Button("Sil", role: .destructive) {
                viewModel.deletePost(post) {
                    dismiss()
                }
            }
        } message: {
            Text("Bu gönderiyi silmek istediğinizden emin misiniz?")
                .foregroundColor(.white)
        }
        .sheet(isPresented: $showCommentSheet) {
            AddCommentView(post: post, onCommentAdded: viewModel.loadComments)
        }
        .onAppear {
            viewModel.loadPostDetails(post)
        }
    }
}

struct PostHeaderView: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(post.username)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(post.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct PostContentView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(post.content)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            if let imageUrl = post.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(16)
                        }
                    }
                }
            }
        }
    }
}

struct PostActionsView: View {
    let post: Post
    let isLiked: Bool
    let likesCount: Int
    let commentsCount: Int
    let onLikeTapped: () -> Void
    let onCommentTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            Button(action: onLikeTapped) {
                HStack(spacing: 8) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .white)
                        .imageScale(.large)
                    Text("\(likesCount)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            
            Button(action: onCommentTapped) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.white)
                        .imageScale(.large)
                    Text("\(commentsCount)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct CommentsListView: View {
    let comments: [Comment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Yorumlar")
                .font(.headline)
                .foregroundColor(.white)
            
            if comments.isEmpty {
                Text("Henüz yorum yapılmamış")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(comments) { comment in
                        CommentRowView(comment: comment)
                    }
                }
            }
        }
    }
} 
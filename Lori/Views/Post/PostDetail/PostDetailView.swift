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
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                },
                trailing: post.userId == Auth.auth().currentUser?.uid ? Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                } : nil
            )
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
            AddCommentView(post: post)
        }
        .onAppear {
            viewModel.loadPostDetails(post)
        }
    }
} 
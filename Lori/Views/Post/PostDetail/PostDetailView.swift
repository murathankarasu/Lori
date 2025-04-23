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
                        // Header ve içerik bölümleri
                        PostHeaderView(post: post)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        PostContentView(post: post)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Dezenformasyon kontrolü görünümü - sadece gerekli durumlarda göster
                        if viewModel.shouldShowDisinformationCheck {
                            disinformationView
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.horizontal)
                        }
                        
                        // Post aksiyonları
                        PostActionsView(
                            post: post,
                            isLiked: viewModel.isLiked,
                            likesCount: viewModel.likesCount,
                            commentsCount: viewModel.comments.count,
                            onLikeTapped: { viewModel.toggleLike() },
                            onCommentTapped: { showCommentSheet = true }
                        )
                        .padding(.horizontal)
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.horizontal)
                        
                        // Yorumlar listesi
                        CommentsListView(comments: viewModel.comments)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                trailing: deleteButton
            )
        }
        .alert("Gönderiyi Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                viewModel.deletePost(post) {
                    dismiss()
                }
            }
        } message: {
            Text("Bu gönderiyi silmek istediğinizden emin misiniz?")
        }
        .sheet(isPresented: $showCommentSheet) {
            AddCommentView(post: post)
        }
        .onAppear {
            viewModel.loadPostDetails(post)
        }
    }
    
    // MARK: - Yardımcı görünümler
    
    @ViewBuilder
    private var deleteButton: some View {
        if post.userId == Auth.auth().currentUser?.uid {
            Button(action: {
                showDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var disinformationView: some View {
        Group {
            if let check = viewModel.disinformationCheck {
                disinformationResultView(check)
            } else if viewModel.isCheckingDisinformation {
                disinformationLoadingView
            }
        }
    }
    
    @ViewBuilder
    private func disinformationResultView(_ check: DisinformationResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if check.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 22))
                    Text("Verified Content")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 22))
                    Text("Unverified Content")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            
            if check.isVerified {
                Text("This content has been verified by Lori's AI-powered fact-checking system in collaboration with trusted sources.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
            
            Text(check.explanation)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 4)
            
            if let sources = check.sources, !sources.isEmpty {
                sourcesView(sources)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var disinformationLoadingView: some View {
        ProgressView("Checking information...")
           .progressViewStyle(CircularProgressViewStyle(tint: .white))
           .foregroundColor(.white)
           .padding()
    }
    
    @ViewBuilder
    private func sourcesView(_ sources: [String]) -> some View {
        VStack(alignment: .leading) {
            Text("Sources:")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ForEach(sources, id: \.self) { source in
                if let url = URL(string: source) {
                    Link(destination: url) {
                        Text(source)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("Invalid source URL: \(source)")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
        }
    }
} 
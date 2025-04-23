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
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        PostContentView(post: post)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Dezenformasyon kontrolü sonucu (ViewModel'dan al)
                        if let check = viewModel.disinformationCheck, check.explanation != "This content does not require verification." {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: check.isVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                        .foregroundColor(check.isVerified ? .green : .yellow)
                                    Text(check.isVerified ? "Verified Content" : "Unverified Content")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                
                                    Spacer() // Butonu sağa yaslamak için

                                    // Manuel Doğrulama Butonu
                                    Button(action: {
                                        viewModel.verifyPostManually()
                                    }) {
                                        if viewModel.isCheckingDisinformation {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.7)
                                        } else {
                                            Image(systemName: "arrow.clockwise.circle")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .disabled(viewModel.isCheckingDisinformation)
                                }
                                
                                Text(check.explanation)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                if let sources = check.sources, !sources.isEmpty {
                                    Text("Sources:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    ForEach(sources, id: \.self) { source in
                                        // URL kontrolü ekleyelim
                                        if let url = URL(string: source) {
                                            Link(destination: url) {
                                                Text(source)
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        } else {
                                            Text("Invalid source URL: \(source)")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else if viewModel.isCheckingDisinformation {
                             // Henüz sonuç yoksa ve kontrol ediliyorsa yükleme göstergesi
                             ProgressView("Checking information...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .foregroundColor(.white)
                                .padding()
                        } else if let check = viewModel.disinformationCheck, check.claims.isEmpty {
                            // Fact Check API'den boş yanıt geldiğinde
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.yellow)
                                    Text("Doğrulama Bilgisi Bulunamadı")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        viewModel.verifyPostManually()
                                    }) {
                                        if viewModel.isCheckingDisinformation {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.7)
                                        } else {
                                            Image(systemName: "arrow.clockwise.circle")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .disabled(viewModel.isCheckingDisinformation)
                                }
                                
                                Text("Bu içerik için henüz doğrulama bilgisi bulunamadı. Lütfen daha sonra tekrar kontrol edin.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            // Doğrulama kontrolü yapılmamışsa buton göster
                            HStack {
                                Button(action: {
                                    viewModel.verifyPostManually()
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.shield")
                                            .foregroundColor(.blue)
                                        Text("Doğrulama Kontrolü")
                                            .foregroundColor(.white)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                .disabled(viewModel.isCheckingDisinformation)
                                
                                if viewModel.isCheckingDisinformation {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.7)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.horizontal)
                        
                        PostActionsView(
                            post: post,
                            isLiked: viewModel.isLiked,
                            likesCount: viewModel.likesCount,
                            commentsCount: viewModel.comments.count,
                            onLikeTapped: { viewModel.toggleLike() }, // Doğrudan ViewModel fonksiyonunu çağır
                            onCommentTapped: { showCommentSheet = true }
                        )
                        .padding(.horizontal)
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.horizontal)
                        
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
                .foregroundColor(.white) // Alert buton renkleri sistem tarafından belirlenir, bu işe yaramayabilir
            Button("Sil", role: .destructive) {
                viewModel.deletePost(post) {
                    dismiss()
                }
            }
        } message: {
            Text("Bu gönderiyi silmek istediğinizden emin misiniz?")
              // .foregroundColor(.white) // Alert mesaj renkleri sistem tarafından belirlenir
        }
        .sheet(isPresented: $showCommentSheet) {
            AddCommentView(post: post)
        }
        .onAppear {
            // ViewModel'ı post ile yükle
            viewModel.loadPostDetails(post)
            // View içindeki checkDisinformation çağrısı kaldırıldı, ViewModel hallediyor
            // checkDisinformation()
        }
    }
} 
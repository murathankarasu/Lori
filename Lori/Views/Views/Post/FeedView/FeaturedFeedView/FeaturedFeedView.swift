import SwiftUI
import FirebaseAuth
// Firebase importları ViewModel'a taşındı
// import FirebaseFirestore

struct FeaturedFeedView: View {
    @Binding var selectedPost: Post?
    @Binding var showPostDetail: Bool
    @StateObject private var viewModel = FeaturedFeedViewModel()
    // @State private var posts: [Post] = [] // ViewModel'a taşındı
    // @State private var isLoading = true // ViewModel'a taşındı
    // @State private var showError = false // ViewModel'a taşındı
    // @State private var errorMessage = "" // ViewModel'a taşındı
    @State private var showCreatePost = false
    @State private var showDirectMessages = false
    
    // Podcast butonu ve ilgili state kaldırıldı
    // @State private var showPodcastView = false
    
    // Listener'lar ViewModel'a taşındı
    // @State private var postsListener: ListenerRegistration?
    // @State private var userListener: ListenerRegistration?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Üst bar
                    HStack {
                        // Mesaj butonu eklendi
                        Button(action: {
                            showDirectMessages = true
                        }) {
                            Image(systemName: "message")
                                .foregroundColor(.white)
                                .padding(.top, 10)
                        }
                        
                        Spacer()
                        
                        Image("loginlogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .padding(.top, 10)
                        
                        Spacer()
                        
                        Button(action: { showCreatePost = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .padding(.top, 10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(viewModel.posts) { post in // ViewModel'daki posts kullanılır
                                    PostCard(post: post)
                                        .onTapGesture {
                                            // Önce etkileşimi kaydet
                                            Task {
                                                 await viewModel.recordPostViewInteraction(post: post)
                                            }
                                            // Sonra detay sayfasına git
                                            selectedPost = post
                                            showPostDetail = true
                                        }
                                }
                            }
                            .padding(.top)
                        }
                        // Pull-to-refresh özelliği eklendi
                        .refreshable {
                            Task {
                                await viewModel.loadPosts() // ViewModel'daki fonksiyon çağrılır
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showCreatePost) {
                CreatePostView()
            }
            .fullScreenCover(isPresented: $showDirectMessages) {
                DirectMessageListView(userId: Auth.auth().currentUser?.uid ?? "")
            }
            // Podcast fullScreenCover kaldırıldı
            .alert(isPresented: $viewModel.showError) { // ViewModel'daki showError ve errorMessage kullanılır
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            // .onAppear eklendi: Eğer post listesi boşsa ilk yüklemeyi yap
            .onAppear {
                if viewModel.posts.isEmpty {
                    Task { // Asenkron fonksiyonu Task içinde çağır
                        await viewModel.loadPosts()
                    }
                }
            }
            // .onDisappear ViewModel'ın deinit'inde hallediliyor
            // .onDisappear {
                // View kapandığında listener'ları temizle
                // postsListener?.remove()
                // userListener?.remove()
            // }
        }
    }
    
    // loadPosts ve ilgili fonksiyonlar ViewModel'a taşındı
    /*
    private func loadPosts() {
        // ... existing code ...
    }
    
    private func loadAllPosts() {
        // ... existing code ...
    }
    
    private func loadPostsByInterests(interests: [String]) {
        // ... existing code ...
    }
    
    private func handlePostsSnapshot(snapshot: QuerySnapshot?, error: Error?) {
        // ... existing code ...
    }
    */
} 
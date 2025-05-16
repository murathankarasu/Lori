import SwiftUI
// import FirebaseAuth // ViewModel'a taşındı
// import FirebaseFirestore // ViewModel'a taşındı

struct FollowingFeedView: View {
    @Binding var selectedPost: Post?
    @Binding var showPostDetail: Bool
    
    // Eski @State değişkenleri kaldırıldı
    // @State private var posts: [Post] = []
    // @State private var isLoading = true
    // @State private var showError = false
    // @State private var errorMessage = ""
    @State private var showCreatePost = false
    
    // ViewModel eklendi
    @StateObject private var viewModel = FollowingFeedViewModel()
    
    // Listener artık ViewModel'da
    // @State private var listener: ListenerRegistration?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Üst bar
                    HStack {
                        // Mesaj butonu eklendi
                        Button(action: {}) {
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
                    
                    // Hata veya Yükleniyor Durumu
                    if viewModel.isLoading {
                        Spacer() // Orta
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Spacer() // Orta
                    } else if let errorMessage = viewModel.errorMessage {
                        Spacer() // Orta
                        Text(errorMessage).foregroundColor(.red).padding()
                        Spacer() // Orta
                    } else {
                        // Gönderi Listesi
                        List { // ScrollView yerine List kullanmak .onAppear için daha iyi olabilir
                            ForEach(viewModel.posts) { post in
                                PostCard(post: post)
                                    .onTapGesture {
                                        selectedPost = post
                                        showPostDetail = true
                                    }
                                    // Liste elemanı göründüğünde daha fazla yüklemeyi kontrol et
                                    .onAppear {
                                        viewModel.loadMoreIfNeeded(currentItem: post)
                                    }
                                    // List stilini ayarla
                                    .listRowInsets(EdgeInsets()) // Kenar boşluklarını sıfırla
                                    .listRowSeparator(.hidden) // Ayırıcıyı gizle
                                    .padding(.vertical, 10) // Postlar arasına boşluk
                            }
                            
                            // Daha fazla yükleniyor göstergesi
                            if viewModel.isFetchingMore {
                                HStack {
                                    Spacer()
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Spacer()
                                }
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 20)
                            }
                        }
                        .listStyle(.plain) // Liste stilini ayarla
                        .background(Color.black) // Liste arkaplanı
                        .refreshable {
                            // Yenileme istendiğinde ilk sayfayı tekrar yükle
                            viewModel.fetchPosts(initial: true)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreatePost) {
                CreatePostView()
            }
            // .alert artık kullanılmıyor, hata mesajı doğrudan gösteriliyor
            // .alert(isPresented: $viewModel.showError) { ... }
            .onAppear {
                // Sayfa her görüntülendiğinde içeriği yenile
                viewModel.fetchPosts(initial: true)
            }
            // .onDisappear listener temizliği ViewModel'ın deinit'inde yapılıyor
            // .onDisappear { ... }
        }
    }
    
    // loadPosts ve createPost fonksiyonları kaldırıldı, ViewModel'a taşındı
    // private func loadPosts() { ... }
    // private func createPost(from document: QueryDocumentSnapshot) -> Post? { ... }
}

struct FollowingFeedView_Previews: PreviewProvider {
    static var previews: some View {
        FollowingFeedView(selectedPost: .constant(nil), showPostDetail: .constant(false))
            // Preview için örnek veri gerekebilir
    }
} 
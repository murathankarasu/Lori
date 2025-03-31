import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FeaturedFeedView: View {
    @Binding var selectedPost: Post?
    @Binding var showPostDetail: Bool
    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCreatePost = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Üst bar
                    HStack {
                        Spacer()
                        
                        Image("loginlogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        
                        Spacer()
                        
                        Button(action: { showCreatePost = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(posts) { post in
                                    PostCard(post: post)
                                        .onTapGesture {
                                            selectedPost = post
                                            showPostDetail = true
                                        }
                                }
                            }
                            .padding(.top)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreatePost) {
                CreatePostView()
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Hata"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("Tamam"))
                )
            }
            .onAppear {
                loadPosts()
            }
        }
    }
    
    private func loadPosts() {
        let db = Firestore.firestore()
        let userId = Auth.auth().currentUser?.uid ?? ""
        isLoading = true
        
        print("\n=== Featured Feed Yükleniyor ===")
        print("Kullanıcı ID: \(userId)")
        
        // Önce posts koleksiyonunda veri var mı kontrol et
        db.collection("posts").limit(to: 1).getDocuments { (checkSnapshot, checkError) in
            if let error = checkError {
                print("❌ Kontrol hatası: \(error.localizedDescription)")
                return
            }
            
            if let count = checkSnapshot?.documents.count, count == 0 {
                print("❌ Posts koleksiyonu boş!")
                isLoading = false
                return
            }
            
            print("✅ Posts koleksiyonunda veri var")
            
            // Kullanıcı bilgilerini al
            db.collection("users").document(userId).getDocument { snapshot, error in
                if let error = error {
                    print("❌ Kullanıcı bilgileri yüklenirken hata: \(error.localizedDescription)")
                    isLoading = false
                    errorMessage = "Kullanıcı bilgileri yüklenemedi: \(error.localizedDescription)"
                    showError = true
                    return
                }
                
                let userData = snapshot?.data()
                print("Kullanıcı verileri: \(String(describing: userData))")
                
                let userInterests = userData?["interests"] as? [String] ?? []
                print("Kullanıcı ilgi alanları: \(userInterests)")
                
                // İlgi alanları boşsa veya yoksa tüm gönderileri yükle
                if userInterests.isEmpty {
                    print("📝 İlgi alanları boş, tüm gönderiler yükleniyor...")
                    db.collection("posts")
                        .order(by: "timestamp", descending: true)
                        .limit(to: 4) // Limit 4'e indirildi
                        .getDocuments { snapshot, error in
                            if let error = error {
                                print("❌ Gönderi yükleme hatası: \(error.localizedDescription)")
                            }
                            if let count = snapshot?.documents.count {
                                print("✅ \(count) gönderi bulundu")
                            }
                            handlePostsSnapshot(snapshot: snapshot, error: error)
                        }
                } else {
                    print("📝 İlgi alanlarına göre gönderiler yükleniyor...")
                    // İlgi alanlarına göre sorgu yap
                    let query = db.collection("posts")
                        .whereField("tags", arrayContainsAny: userInterests)
                        .order(by: "timestamp", descending: true)
                        .limit(to: 4) // Limit 4'e indirildi
                    
                    query.getDocuments { snapshot, error in
                        if let error = error {
                            print("❌ İlgi alanlarına göre yükleme hatası: \(error.localizedDescription)")
                        }
                        if let count = snapshot?.documents.count {
                            print("✅ \(count) gönderi bulundu")
                        }
                        handlePostsSnapshot(snapshot: snapshot, error: error)
                    }
                }
            }
        }
    }
    
    private func handlePostsSnapshot(snapshot: QuerySnapshot?, error: Error?) {
        DispatchQueue.main.async {
            isLoading = false
            
            if let error = error {
                print("❌ Gönderiler yüklenirken hata: \(error.localizedDescription)")
                errorMessage = "Gönderiler yüklenirken bir hata oluştu: \(error.localizedDescription)"
                showError = true
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("❌ Gönderi bulunamadı")
                posts = []
                return
            }
            
            print("📝 \(documents.count) gönderi işleniyor...")
            
            posts = documents.compactMap { document -> Post? in
                let data = document.data()
                print("Gönderi verisi:")
                print("- ID: \(document.documentID)")
                print("- Kullanıcı: \(data["username"] as? String ?? "Bilinmiyor")")
                print("- İçerik: \(data["content"] as? String ?? "")")
                print("- Etiketler: \(data["tags"] as? [String] ?? [])")
                
                return Post(
                    id: document.documentID,
                    userId: data["userId"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    content: data["content"] as? String ?? "",
                    imageUrl: data["imageUrl"] as? String,
                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                    likes: data["likes"] as? Int ?? 0,
                    comments: (data["comments"] as? [[String: Any]])?.compactMap { commentData in
                        guard let id = commentData["id"] as? String,
                              let userId = commentData["userId"] as? String,
                              let username = commentData["username"] as? String,
                              let content = commentData["content"] as? String,
                              let timestamp = (commentData["timestamp"] as? Timestamp)?.dateValue() else {
                            return nil
                        }
                        return Comment(id: id, userId: userId, username: username, content: content, timestamp: timestamp)
                    } ?? [],
                    isViewed: data["isViewed"] as? Bool ?? false,
                    tags: data["tags"] as? [String] ?? []
                )
            }
            
            print("✅ \(posts.count) gönderi başarıyla yüklendi")
            print("===================\n")
        }
    }
} 
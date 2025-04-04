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
    
    // Listener'ları tutmak için
    @State private var postsListener: ListenerRegistration?
    @State private var userListener: ListenerRegistration?
    
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
            .onDisappear {
                // View kapandığında listener'ları temizle
                postsListener?.remove()
                userListener?.remove()
            }
        }
    }
    
    private func loadPosts() {
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Önceki listener'ları temizle
        postsListener?.remove()
        userListener?.remove()
        
        // Kullanıcı bilgilerini dinle
        userListener = db.collection("users").document(userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    errorMessage = "Kullanıcı bilgileri yüklenemedi: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                    return
                }
                
                let userInterests = snapshot?.data()?["interests"] as? [String] ?? []
                
                // İlgi alanları boşsa veya yoksa tüm gönderileri yükle
                if userInterests.isEmpty {
                    loadAllPosts()
                } else {
                    loadPostsByInterests(interests: userInterests)
                }
            }
    }
    
    private func loadAllPosts() {
        let db = Firestore.firestore()
        
        postsListener = db.collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .addSnapshotListener { snapshot, error in
                handlePostsSnapshot(snapshot: snapshot, error: error)
            }
    }
    
    private func loadPostsByInterests(interests: [String]) {
        let db = Firestore.firestore()
        
        postsListener = db.collection("posts")
            .whereField("interests", arrayContainsAny: interests)
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .addSnapshotListener { snapshot, error in
                handlePostsSnapshot(snapshot: snapshot, error: error)
            }
    }
    
    private func handlePostsSnapshot(snapshot: QuerySnapshot?, error: Error?) {
        isLoading = false
        
        if let error = error {
            errorMessage = "Gönderiler yüklenemedi: \(error.localizedDescription)"
            showError = true
            return
        }
        
        guard let documents = snapshot?.documents else {
            posts = []
            return
        }
        
        posts = documents.compactMap { document -> Post? in
            let data = document.data()
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
                    return Comment(
                        id: id,
                        postId: document.documentID,
                        userId: userId,
                        username: username,
                        content: content,
                        timestamp: timestamp
                    )
                } ?? [],
                isViewed: data["isViewed"] as? Bool ?? false,
                tags: data["tags"] as? [String] ?? [],
                category: data["category"] as? String ?? "featured",
                mentions: data["mentions"] as? [String] ?? [],
                interests: data["interests"] as? [String] ?? []
            )
        }
    }
} 
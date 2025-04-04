import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FollowingFeedView: View {
    @Binding var selectedPost: Post?
    @Binding var showPostDetail: Bool
    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCreatePost = false
    
    // Listener'ları tutmak için
    @State private var listener: ListenerRegistration?
    
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
                // View kapandığında listener'ı temizle
                listener?.remove()
            }
        }
    }
    
    private func loadPosts() {
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Önceki listener varsa temizle
        listener?.remove()
        
        // Kullanıcının takip ettiği kişilerin listesini al
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Kullanıcı bilgileri yüklenemedi: \(error.localizedDescription)"
                showError = true
                isLoading = false
                return
            }
            
            var following = snapshot?.data()?["following"] as? [String] ?? []
            if !following.contains(userId) {
                following.append(userId)
            }
            
            if following.isEmpty {
                isLoading = false
                return
            }
            
            // Tek bir listener ile gönderileri dinle
            listener = db.collection("posts")
                .whereField("userId", in: following)
                .order(by: "timestamp", descending: true)
                .limit(to: 20)
                .addSnapshotListener { snapshot, error in
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
                            category: data["category"] as? String ?? "following",
                            mentions: data["mentions"] as? [String] ?? [],
                            interests: data["interests"] as? [String] ?? []
                        )
                    }
                }
        }
    }
} 
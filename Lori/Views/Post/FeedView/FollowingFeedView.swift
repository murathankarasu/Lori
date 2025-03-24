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
        
        // Kullanıcının takip ettiği kişilerin gönderilerini yükle
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Kullanıcı bilgileri yüklenirken hata oluştu: \(error.localizedDescription)"
                showError = true
                isLoading = false
                return
            }
            
            // Kullanıcının takip ettiği kişilerin listesini al
            var following = snapshot?.data()?["following"] as? [String] ?? []
            if !following.contains(userId) {
                following.append(userId)
            }
            
            if following.isEmpty {
                isLoading = false
                return
            }
            
            // Her bir kullanıcının gönderilerini ayrı ayrı yükle
            var allPosts: [Post] = []
            let group = DispatchGroup()
            
            for followedUserId in following {
                group.enter()
                
                db.collection("posts")
                    .whereField("userId", isEqualTo: followedUserId)
                    .order(by: "timestamp", descending: true)
                    .limit(to: 5)
                    .getDocuments { snapshot, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("Gönderi yüklenirken hata: \(error.localizedDescription)")
                            return
                        }
                        
                        if let documents = snapshot?.documents {
                            let userPosts = documents.compactMap { document -> Post? in
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
                                        return Comment(id: id, userId: userId, username: username, content: content, timestamp: timestamp)
                                    } ?? [],
                                    isViewed: data["isViewed"] as? Bool ?? false,
                                    tags: data["tags"] as? [String] ?? []
                                )
                            }
                            allPosts.append(contentsOf: userPosts)
                        }
                    }
            }
            
            group.notify(queue: .main) {
                // Tüm gönderileri tarihe göre sırala
                posts = allPosts.sorted { $0.timestamp > $1.timestamp }
                isLoading = false
            }
        }
    }
} 
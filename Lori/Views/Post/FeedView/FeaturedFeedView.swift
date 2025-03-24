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
        
        // Önce kullanıcının ilgi alanlarını al
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Kullanıcı bilgileri yüklenirken hata oluştu: \(error.localizedDescription)")
                isLoading = false
                errorMessage = "Kullanıcı bilgileri yüklenemedi: \(error.localizedDescription)"
                showError = true
                return
            }
            
            let userInterests = snapshot?.data()?["interests"] as? [String] ?? []
            
            // İlgi alanları boşsa veya yoksa tüm gönderileri yükle
            if userInterests.isEmpty {
                db.collection("posts")
                    .order(by: "timestamp", descending: true)
                    .limit(to: 20)
                    .getDocuments(completion: handlePostsSnapshot)
            } else {
                // İlgi alanlarına göre gönderileri yükle
                db.collection("posts")
                    .whereField("tags", arrayContainsAny: userInterests)
                    .order(by: "timestamp", descending: true)
                    .limit(to: 20)
                    .getDocuments(completion: handlePostsSnapshot)
            }
        }
    }
    
    private func handlePostsSnapshot(snapshot: QuerySnapshot?, error: Error?) {
        DispatchQueue.main.async {
            isLoading = false
            
            if let error = error {
                errorMessage = "Gönderiler yüklenirken bir hata oluştu: \(error.localizedDescription)"
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
                        return Comment(id: id, userId: userId, username: username, content: content, timestamp: timestamp)
                    } ?? [],
                    isViewed: data["isViewed"] as? Bool ?? false,
                    tags: data["tags"] as? [String] ?? []
                )
            }
        }
    }
} 
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Post: Identifiable {
    let id: String
    let username: String
    let content: String
    let timestamp: Date
    var likes: Int
    
    init(id: String, username: String, content: String, timestamp: Date, likes: Int = 0) {
        self.id = id
        self.username = username
        self.content = content
        self.timestamp = timestamp
        self.likes = likes
    }
}

struct FeedView: View {
    @State private var posts: [Post] = []
    @State private var newPost: String = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Post oluşturma alanı
                    VStack(spacing: 10) {
                        TextField("Ne düşünüyorsun?", text: $newPost)
                            .textFieldStyle(CustomTextFieldStyle())
                            .padding()
                        
                        Button(action: createPost) {
                            Text("Paylaş")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color.white)
                                .cornerRadius(20)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    
                    // Post listesi
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(posts) { post in
                                PostView(post: post)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: signOut) {
                        Text("Çıkış Yap")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            fetchPosts()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Bilgi"), message: Text(alertMessage), dismissButton: .default(Text("Tamam")))
        }
    }
    
    private func createPost() {
        guard !newPost.isEmpty else { return }
        guard let currentUser = Auth.auth().currentUser else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        // Önce kullanıcı adını al
        db.collection("users").document(currentUser.uid).getDocument { (document, error) in
            if let document = document, let username = document.data()?["username"] as? String {
                // Post oluştur
                let postData: [String: Any] = [
                    "username": username,
                    "content": newPost,
                    "timestamp": FieldValue.serverTimestamp(),
                    "likes": 0
                ]
                
                db.collection("posts").addDocument(data: postData) { error in
                    if let error = error {
                        alertMessage = "Post paylaşılırken bir hata oluştu: \(error.localizedDescription)"
                        showAlert = true
                    } else {
                        newPost = ""
                        fetchPosts()
                    }
                    isLoading = false
                }
            }
        }
    }
    
    private func fetchPosts() {
        let db = Firestore.firestore()
        db.collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    alertMessage = "Postlar yüklenirken bir hata oluştu: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let documents = querySnapshot?.documents else { return }
                
                posts = documents.compactMap { document -> Post? in
                    let data = document.data()
                    guard let username = data["username"] as? String,
                          let content = data["content"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp,
                          let likes = data["likes"] as? Int else { return nil }
                    
                    return Post(
                        id: document.documentID,
                        username: username,
                        content: content,
                        timestamp: timestamp.dateValue(),
                        likes: likes
                    )
                }
            }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            alertMessage = "Çıkış yapılırken bir hata oluştu: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

struct PostView: View {
    let post: Post
    @State private var isLiked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("@\(post.username)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(post.timestamp.formatted())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(post.content)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            HStack {
                Button(action: {
                    isLiked.toggle()
                }) {
                    HStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .white)
                        Text("\(post.likes)")
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
} 
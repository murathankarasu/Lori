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
        isLoading = true
        
        print("Kullanıcı ID: \(userId)") // Debug için
        
        // Kullanıcının takip ettiği kişilerin gönderilerini yükle
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Kullanıcı bilgileri yüklenirken hata: \(error.localizedDescription)") // Debug için
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
            
            print("Takip edilen kullanıcılar: \(following)") // Debug için
            
            if following.isEmpty {
                print("Takip edilen kullanıcı yok") // Debug için
                isLoading = false
                return
            }
            
            // Tüm takip edilen kullanıcıların gönderilerini tek bir sorguda al
            print("Takip edilen kullanıcıların gönderileri yükleniyor...") // Debug için
            db.collection("posts")
                .whereField("userId", in: following)
                .order(by: "timestamp", descending: true)
                .limit(to: 20)
                .getDocuments { snapshot, error in
                    print("Takip edilen kullanıcıların gönderileri yüklendi. Gönderi sayısı: \(snapshot?.documents.count ?? 0)") // Debug için
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        if let error = error {
                            print("Gönderiler yüklenirken hata: \(error.localizedDescription)") // Debug için
                            errorMessage = "Gönderiler yüklenirken hata oluştu: \(error.localizedDescription)"
                            showError = true
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            print("Gönderi bulunamadı") // Debug için
                            posts = []
                            return
                        }
                        
                        print("\(documents.count) gönderi bulundu") // Debug için
                        
                        posts = documents.compactMap { document -> Post? in
                            let data = document.data()
                            print("Gönderi verisi: \(data)") // Debug için
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
                        
                        print("Yüklenen gönderi sayısı: \(posts.count)") // Debug için
                    }
                }
        }
    }
} 
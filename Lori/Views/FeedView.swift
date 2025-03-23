import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FeedView: View {
    @State private var posts: [Post] = []
    @State private var recommendedPosts: [Post] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showProfileView = false
    @State private var showSettingsView = false
    @State private var followingUsers: Set<String> = []
    @State private var userInterests: [String] = []
    @State private var viewedPosts: Set<String> = []
    @State private var showNewPostSheet = false
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Üst bar
                    HStack {
                        Button(action: { showProfileView = true }) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Image("loginlogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        
                        Spacer()
                        
                        Button(action: { showSettingsView = true }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    
                    // Tab görünümü
                    TabView {
                        // Takip edilen postlar
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                if posts.isEmpty {
                                    Text("Henüz takip ettiğiniz kimse yok")
                                        .foregroundColor(.gray)
                                        .padding(.top, 50)
                                } else {
                                    ForEach(posts) { post in
                                        PostView(post: post, isFollowing: followingUsers.contains(post.userId)) { userId in
                                            toggleFollow(userId: userId)
                                        }
                                        .onAppear {
                                            if !post.isViewed {
                                                markPostAsViewed(post)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        .tabItem {
                            Text("Takip")
                        }
                        
                        // Önerilen postlar
                        ScrollView {
                            LazyVStack(spacing: 15) {
                                if recommendedPosts.isEmpty {
                                    Text("Henüz öneri bulunmuyor")
                                        .foregroundColor(.gray)
                                        .padding(.top, 50)
                                } else {
                                    ForEach(recommendedPosts) { post in
                                        PostView(post: post, isFollowing: followingUsers.contains(post.userId)) { userId in
                                            toggleFollow(userId: userId)
                                        }
                                        .onAppear {
                                            if !post.isViewed {
                                                markPostAsViewed(post)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        .tabItem {
                            Text("Önerilen")
                        }
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .never))
                }
                
                // Yeni gönderi oluşturma butonu
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showNewPostSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 60, height: 60)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await fetchUserData()
                await fetchPosts()
            }
        }
        .sheet(isPresented: $showProfileView) {
            Text("Profil Görünümü")
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView(isLoggedIn: $isLoggedIn)
        }
        .sheet(isPresented: $showNewPostSheet) {
            CreatePostView()
        }
        .alert("Bilgi", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func fetchUserData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if document.exists {
                if let following = document.data()?["following"] as? [String] {
                    followingUsers = Set(following)
                }
                if let interests = document.data()?["interests"] as? [String] {
                    userInterests = interests
                    await fetchRecommendedPosts()
                }
            }
        } catch {
            print("Kullanıcı verisi alınırken hata: \(error.localizedDescription)")
        }
    }
    
    private func fetchPosts() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        do {
            let querySnapshot = try await db.collection("posts")
                .whereField("userId", in: Array(followingUsers) + [currentUserId])
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            posts = querySnapshot.documents.compactMap { document -> Post? in
                let data = document.data()
                guard let username = data["username"] as? String,
                      let content = data["content"] as? String,
                      let timestamp = data["timestamp"] as? Timestamp,
                      let likes = data["likes"] as? Int,
                      let userId = data["userId"] as? String else { return nil }
                
                return Post(
                    id: document.documentID,
                    username: username,
                    content: content,
                    timestamp: timestamp.dateValue(),
                    likes: likes,
                    userId: userId,
                    tags: data["tags"] as? [String] ?? [],
                    isViewed: false
                )
            }
        } catch {
            print("Postlar alınırken hata: \(error.localizedDescription)")
        }
    }
    
    private func fetchRecommendedPosts() async {
        guard !userInterests.isEmpty else { return }
        let db = Firestore.firestore()
        
        do {
            let usersSnapshot = try await db.collection("users")
                .whereField("interests", arrayContainsAny: userInterests)
                .getDocuments()
            
            let recommendedUserIds = usersSnapshot.documents
                .map { $0.documentID }
                .filter { $0 != Auth.auth().currentUser?.uid }
            
            if !recommendedUserIds.isEmpty {
                let postsSnapshot = try await db.collection("posts")
                    .whereField("userId", in: recommendedUserIds)
                    .order(by: "timestamp", descending: true)
                    .getDocuments()
                
                recommendedPosts = postsSnapshot.documents.compactMap { document -> Post? in
                    let data = document.data()
                    guard let username = data["username"] as? String,
                          let content = data["content"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp,
                          let likes = data["likes"] as? Int,
                          let userId = data["userId"] as? String else { return nil }
                    
                    return Post(
                        id: document.documentID,
                        username: username,
                        content: content,
                        timestamp: timestamp.dateValue(),
                        likes: likes,
                        userId: userId,
                        tags: data["tags"] as? [String] ?? [],
                        isViewed: false
                    )
                }
            }
        } catch {
            print("Önerilen postlar alınırken hata: \(error.localizedDescription)")
        }
    }
    
    private func toggleFollow(userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        if followingUsers.contains(userId) {
            followingUsers.remove(userId)
        } else {
            followingUsers.insert(userId)
        }
        
        Task {
            do {
                try await db.collection("users").document(currentUserId).updateData([
                    "following": Array(followingUsers)
                ])
            } catch {
                print("Takip etme hatası: \(error.localizedDescription)")
            }
        }
    }
    
    private func markPostAsViewed(_ post: Post) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        Task {
            do {
                let document = try await db.collection("users").document(userId).getDocument()
                if document.exists {
                    var currentInterests = document.data()?["interests"] as? [String] ?? []
                    var interestCounts = document.data()?["interestCounts"] as? [String: Int] ?? [:]
                    
                    for tag in post.tags {
                        interestCounts[tag] = (interestCounts[tag] ?? 0) + 1
                    }
                    
                    let topInterests = interestCounts.sorted { $0.value > $1.value }
                        .prefix(5)
                        .map { $0.key }
                    
                    currentInterests = Array(Set(currentInterests + topInterests))
                    
                    try await db.collection("users").document(userId).updateData([
                        "interests": currentInterests,
                        "interestCounts": interestCounts,
                        "viewedPosts": FieldValue.arrayUnion([post.id])
                    ])
                    
                    userInterests = currentInterests
                    await fetchRecommendedPosts()
                }
            } catch {
                print("Post görüntüleme hatası: \(error.localizedDescription)")
            }
        }
    }
}

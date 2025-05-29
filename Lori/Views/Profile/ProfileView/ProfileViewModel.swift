import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username = ""
    @Published var bio = ""
    @Published var interests: [String] = []
    @Published var profileImageUrl: String?
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var followersCount = 0
    @Published var followingCount = 0
    @Published var isCurrentUser = false
    @Published var isFollowing = false
    @Published var hasMorePosts = true
    @Published var hasCommunityBadge: Bool = false
    private var lastDocument: DocumentSnapshot?
    private let pageSize = 20
    
    let userId: String
    private let db = Firestore.firestore()
    private var userListener: ListenerRegistration?
    private var followersListener: ListenerRegistration?
    private var followingListener: ListenerRegistration?
    private let notificationService = NotificationService.shared
    
    init(userId: String? = nil) {
        let effectiveUserId = userId ?? Auth.auth().currentUser?.uid ?? ""
        self.userId = effectiveUserId
        self.isCurrentUser = userId == nil || userId == Auth.auth().currentUser?.uid
        
        Task {
            await fetchUserProfile()
            await fetchUserPosts()
            await checkCommunityBadge()
            if !isCurrentUser {
                await checkIfFollowing()
            }
        }
    }
    
    deinit {
        userListener?.remove()
        followersListener?.remove()
        followingListener?.remove()
        print("[ProfileViewModel] Listeners removed for user: \(userId)")
    }
    
    func fetchUserProfile() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("Kullanıcı profili yükleniyor: \(userId)")
            
            let userDoc = try await db.collection("users").document(userId).getDocument()
            
            guard let userData = userDoc.data() else {
                print("❌ Kullanıcı verisi bulunamadı")
                errorMessage = "Kullanıcı bulunamadı"
                showError = true
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı"])
            }
            
            username = userData["username"] as? String ?? ""
            bio = userData["bio"] as? String ?? ""
            interests = userData["interests"] as? [String] ?? []
            profileImageUrl = userData["profileImageUrl"] as? String
            
            print("✅ Kullanıcı profili yüklendi:")
            print("- Kullanıcı adı: \(username)")
            print("- Biyografi: \(bio)")
            print("- İlgi alanları: \(interests)")
            print("- Profil resmi URL: \(profileImageUrl ?? "Yok")")
            
            // Listener'ları kur (veya mevcutları kaldırıp yeniden kur)
            setupCountListeners()
            
        } catch {
            print("❌ Profil yükleme hatası: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func fetchUserPosts() async {
        await MainActor.run { 
            isLoading = true
            errorMessage = ""
            // İlk yüklemede postları temizle
            posts = []
        }
        
        defer { Task { await MainActor.run { isLoading = false } } }
        
        do {
            print("[ProfileViewModel] Fetching posts for user: \(userId)")
            
            let query = db.collection("posts")
                .whereField("userId", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
                .limit(to: pageSize)
            
            let querySnapshot = try await query.getDocuments()
            let docs = querySnapshot.documents
            
            print("[ProfileViewModel] Found \(docs.count) posts")
            
            let newPosts = docs.compactMap { document in
                let data = document.data()
                let id = document.documentID
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                let userId = data["userId"] as? String ?? ""
                let username = data["username"] as? String ?? ""
                let content = data["content"] as? String ?? ""
                let imageUrl = data["imageUrl"] as? String
                let profileImageUrl = data["profileImageUrl"] as? String
                let likes = data["likes"] as? Int ?? 0
                let comments: [Comment] = []
                let tags = data["tags"] as? [String] ?? []
                let category = data["category"] as? String ?? "featured"
                let mentions = data["mentions"] as? [String] ?? []
                return Post(
                    id: id,
                    userId: userId,
                    username: username,
                    content: content,
                    imageUrl: imageUrl,
                    profileImageUrl: profileImageUrl,
                    timestamp: timestamp,
                    likes: likes,
                    comments: comments,
                    tags: tags,
                    category: category,
                    mentions: mentions
                )
            }
            await MainActor.run {
                self.posts = newPosts
                self.lastDocument = docs.last
                self.hasMorePosts = docs.count == self.pageSize
            }
        } catch {
            print("[ProfileViewModel] Error fetching posts: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    func fetchMoreUserPosts() async {
        guard !isLoading, hasMorePosts, let lastDoc = lastDocument else { return }
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        do {
            let query = db.collection("posts")
                .whereField("userId", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
                .start(afterDocument: lastDoc)
                .limit(to: pageSize)
            let querySnapshot = try await query.getDocuments()
            let docs = querySnapshot.documents
            let newPosts = docs.compactMap { document in
                let data = document.data()
                let id = document.documentID
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                let userId = data["userId"] as? String ?? ""
                let username = data["username"] as? String ?? ""
                let content = data["content"] as? String ?? ""
                let imageUrl = data["imageUrl"] as? String
                let profileImageUrl = data["profileImageUrl"] as? String
                let likes = data["likes"] as? Int ?? 0
                let comments: [Comment] = []
                let tags = data["tags"] as? [String] ?? []
                let category = data["category"] as? String ?? "featured"
                let mentions = data["mentions"] as? [String] ?? []
                return Post(
                    id: id,
                    userId: userId,
                    username: username,
                    content: content,
                    imageUrl: imageUrl,
                    profileImageUrl: profileImageUrl,
                    timestamp: timestamp,
                    likes: likes,
                    comments: comments,
                    tags: tags,
                    category: category,
                    mentions: mentions
                )
            }
            await MainActor.run {
                self.posts.append(contentsOf: newPosts)
                self.lastDocument = docs.last
                self.hasMorePosts = docs.count == self.pageSize
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    func toggleFollow() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            isFollowing.toggle()
            let wasFollowing = !isFollowing
            
            if wasFollowing {
                // Takibi bırak
                try await db.collection("users").document(currentUserId).updateData([
                    "following": FieldValue.arrayRemove([userId])
                ])
                try await db.collection("users").document(userId).updateData([
                    "followers": FieldValue.arrayRemove([currentUserId])
                ])
                followersCount -= 1
            } else {
                // Takip et
                try await db.collection("users").document(currentUserId).updateData([
                    "following": FieldValue.arrayUnion([userId])
                ])
                try await db.collection("users").document(userId).updateData([
                    "followers": FieldValue.arrayUnion([currentUserId])
                ])
                followersCount += 1
                
                // Takip bildirimi gönder (sadece takip ettiğinde)
                notificationService.sendSocialNotification(
                    type: .follow,
                    from: currentUserId,
                    to: userId,
                    postId: nil
                )
            }
        } catch {
            // Hata durumunda UI'ı eski haline getir
            isFollowing.toggle()
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func checkIfFollowing() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let doc = try await db.collection("users").document(currentUserId).getDocument()
            let following = doc.data()?["following"] as? [String] ?? []
            isFollowing = following.contains(userId)
        } catch {
            print("Takip durumu kontrol edilemedi: \(error.localizedDescription)")
        }
    }
    
    private func setupCountListeners() {
        followersListener?.remove()
        followingListener?.remove()
        
        // Listener for followers count
        followersListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching followers count snapshot: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                let count = (document.data()?["followers"] as? [String])?.count ?? 0
                // Sadece değiştiyse güncelleme (gereksiz UI güncellemelerini önlemek için)
                if self?.followersCount != count {
                    self?.followersCount = count
                    print("[ProfileViewModel] Followers count updated: \(count)")
                }
            }
        
        // Listener for following count
        followingListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching following count snapshot: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                let count = (document.data()?["following"] as? [String])?.count ?? 0
                if self?.followingCount != count {
                    self?.followingCount = count
                     print("[ProfileViewModel] Following count updated: \(count)")
                }
            }
    }
    
    /// Topluluk rozeti kontrolü
    func checkCommunityBadge() async {
        do {
            let result = try await UserEmotionService.shared.hasCommunityBadge(userId: userId)
            await MainActor.run {
                self.hasCommunityBadge = result
            }
        } catch {
            print("Topluluk rozeti kontrolünde hata: \(error)")
            await MainActor.run {
                self.hasCommunityBadge = false
            }
        }
    }
} 
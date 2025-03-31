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
    
    let userId: String
    private let db = Firestore.firestore()
    
    init(userId: String? = nil) {
        self.userId = userId ?? Auth.auth().currentUser?.uid ?? ""
        self.isCurrentUser = userId == nil || userId == Auth.auth().currentUser?.uid
        
        Task {
            await fetchUserProfile()
            await fetchUserPosts()
            if !isCurrentUser {
                await checkIfFollowing()
            }
        }
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
            
            // Takipçi ve takip edilen sayılarını al
            let followersDoc = try await db.collection("followers").document(userId).getDocument()
            let followingDoc = try await db.collection("following").document(userId).getDocument()
            
            followersCount = (followersDoc.data()?["users"] as? [String])?.count ?? 0
            followingCount = (followingDoc.data()?["users"] as? [String])?.count ?? 0
            
            print("- Takipçi sayısı: \(followersCount)")
            print("- Takip edilen sayısı: \(followingCount)")
            
        } catch {
            print("❌ Profil yükleme hatası: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func fetchUserPosts() async {
        do {
            print("Kullanıcı gönderileri yükleniyor: \(userId)")
            
            let querySnapshot = try await db.collection("posts")
                .whereField("userId", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            posts = querySnapshot.documents.compactMap { document in
                let data = document.data()
                
                // Timestamp'i Date'e çevir
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                
                return Post(
                    id: document.documentID,
                    userId: data["userId"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    content: data["content"] as? String ?? "",
                    imageUrl: data["imageUrl"] as? String,
                    timestamp: timestamp,
                    likes: data["likes"] as? Int ?? 0,
                    comments: [], // Boş array olarak başlat, gerekirse sonra doldur
                    isViewed: data["isViewed"] as? Bool ?? false,
                    tags: data["tags"] as? [String] ?? [],
                    category: data["category"] as? String ?? "featured",
                    mentions: data["mentions"] as? [String] ?? []
                )
            }
            
            print("✅ \(posts.count) gönderi yüklendi")
            
        } catch {
            print("❌ Gönderi yükleme hatası: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func toggleFollow() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        do {
            isFollowing.toggle()
            let wasFollowing = !isFollowing
            
            if wasFollowing {
                // Takibi bırak
                try await db.collection("followers").document(userId).updateData([
                    "users": FieldValue.arrayRemove([currentUserId])
                ])
                try await db.collection("following").document(currentUserId).updateData([
                    "users": FieldValue.arrayRemove([userId])
                ])
                followersCount -= 1
            } else {
                // Takip et
                try await db.collection("followers").document(userId).setData([
                    "users": FieldValue.arrayUnion([currentUserId])
                ], merge: true)
                try await db.collection("following").document(currentUserId).setData([
                    "users": FieldValue.arrayUnion([userId])
                ], merge: true)
                followersCount += 1
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
            let doc = try await db.collection("following").document(currentUserId).getDocument()
            let following = doc.data()?["users"] as? [String] ?? []
            isFollowing = following.contains(userId)
        } catch {
            print("Takip durumu kontrol edilemedi: \(error.localizedDescription)")
        }
    }
} 
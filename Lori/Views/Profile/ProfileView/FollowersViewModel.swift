import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FollowersViewModel: ObservableObject {
    @Published var followers: [User] = []
    @Published var isLoading = true
    @Published var followStatus: [String: Bool] = [:] // [userId: isFollowing]
    
    let userId: String // Profili görüntülenen kullanıcı
    private let currentUserId: String? // Mevcut giriş yapmış kullanıcı
    private let db = Firestore.firestore()
    
    init(userId: String) {
        self.userId = userId
        self.currentUserId = Auth.auth().currentUser?.uid
        Task {
            await loadFollowers()
        }
    }
    
    func loadFollowers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. Takipçi ID'lerini al
            let followersDoc = try await db.collection("followers").document(userId).getDocument()
            let followerIds = followersDoc.data()?["users"] as? [String] ?? []
            
            guard !followerIds.isEmpty else {
                self.followers = []
                return
            }
            
            // 2. Takipçi kullanıcı bilgilerini al
            var loadedFollowers: [User] = []
            let querySnapshot = try await db.collection("users").whereField(FieldPath.documentID(), in: followerIds).getDocuments()
            
            for document in querySnapshot.documents {
                let data = document.data()
                let user = User(
                    id: document.documentID,
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    profileImageUrl: data["profileImageUrl"] as? String,
                    bio: data["bio"] as? String,
                    // Takipçi/takip edilen sayıları bu aşamada gerekli değil, sıfır bırakılabilir.
                    followers: 0,
                    following: 0,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    isVerified: data["isVerified"] as? Bool ?? false
                )
                loadedFollowers.append(user)
            }
            self.followers = loadedFollowers
            
            // 3. Mevcut kullanıcının takip durumlarını kontrol et
            await checkFollowStatus(for: followerIds)
            
        } catch {
            print("❌ Takipçi yükleme hatası: \(error.localizedDescription)")
            // Hata yönetimi eklenebilir (örn: @Published var errorMessage)
        }
    }
    
    private func checkFollowStatus(for userIds: [String]) async {
        guard let currentUserId = self.currentUserId, !userIds.isEmpty else { return }
        
        do {
            let followingDoc = try await db.collection("following").document(currentUserId).getDocument()
            let followingIds = followingDoc.data()?["users"] as? [String] ?? []
            var statusMap: [String: Bool] = [:]
            for id in userIds {
                statusMap[id] = followingIds.contains(id)
            }
            self.followStatus = statusMap
        } catch {
            print("❌ Takip durumu kontrol hatası: \(error.localizedDescription)")
        }
    }
    
    func toggleFollow(userToToggle: User) async {
        guard let currentUserId = self.currentUserId, currentUserId != userToToggle.id else { return }
        
        let targetUserId = userToToggle.id
        let isCurrentlyFollowing = followStatus[targetUserId] ?? false
        
        // Optimistic UI update
        followStatus[targetUserId] = !isCurrentlyFollowing
        
        do {
            let followingRef = db.collection("following").document(currentUserId)
            let followersRef = db.collection("followers").document(targetUserId)
            
            if isCurrentlyFollowing {
                // Takibi Bırak
                try await followingRef.updateData(["users": FieldValue.arrayRemove([targetUserId])])
                try await followersRef.updateData(["users": FieldValue.arrayRemove([currentUserId])])
            } else {
                // Takip Et
                try await followingRef.setData(["users": FieldValue.arrayUnion([targetUserId])], merge: true)
                try await followersRef.setData(["users": FieldValue.arrayUnion([currentUserId])], merge: true)
            }
        } catch {
            print("❌ Takip toggle hatası: \(error.localizedDescription)")
            // Hata durumunda UI'ı geri al
            followStatus[targetUserId] = isCurrentlyFollowing
            // Hata mesajı gösterilebilir
        }
    }
} 
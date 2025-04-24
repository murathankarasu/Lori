import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FollowingViewModel: ObservableObject {
    @Published var following: [User] = []
    @Published var isLoading = true
    @Published var followStatus: [String: Bool] = [:] // [userId: isFollowing]
    
    let userId: String // Profili görüntülenen kullanıcı
    private let currentUserId: String? // Mevcut giriş yapmış kullanıcı
    private let db = Firestore.firestore()
    
    init(userId: String) {
        self.userId = userId
        self.currentUserId = Auth.auth().currentUser?.uid
        Task {
            await loadFollowing()
        }
    }
    
    func loadFollowing() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. Takip edilen ID'lerini al
            let followingDoc = try await db.collection("following").document(userId).getDocument()
            let followingIds = followingDoc.data()?["users"] as? [String] ?? []
            
            guard !followingIds.isEmpty else {
                self.following = []
                return
            }
            
            // 2. Takip edilen kullanıcı bilgilerini al
            var loadedFollowing: [User] = []
            let querySnapshot = try await db.collection("users").whereField(FieldPath.documentID(), in: followingIds).getDocuments()
            
            for document in querySnapshot.documents {
                let data = document.data()
                let user = User(
                    id: document.documentID,
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    profileImageUrl: data["profileImageUrl"] as? String,
                    bio: data["bio"] as? String,
                    followers: 0,
                    following: 0,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    isVerified: data["isVerified"] as? Bool ?? false
                )
                loadedFollowing.append(user)
            }
            self.following = loadedFollowing
            
            // 3. Mevcut kullanıcının takip durumlarını kontrol et (Takip Edilenler listesi için de gerekli)
            await checkFollowStatus(for: followingIds)
            
        } catch {
            print("❌ Takip edilen yükleme hatası: \(error.localizedDescription)")
        }
    }
    
    private func checkFollowStatus(for userIds: [String]) async {
        guard let currentUserId = self.currentUserId, !userIds.isEmpty else { return }
        
        do {
            let followingDoc = try await db.collection("following").document(currentUserId).getDocument()
            let currentlyFollowingIds = followingDoc.data()?["users"] as? [String] ?? []
            var statusMap: [String: Bool] = [:]
            for id in userIds {
                statusMap[id] = currentlyFollowingIds.contains(id)
            }
            self.followStatus = statusMap
        } catch {
            print("❌ Takip durumu kontrol hatası: \(error.localizedDescription)")
        }
    }
    
    // toggleFollow fonksiyonu FollowersViewModel ile aynı, kopyalanabilir veya ortak bir yere taşınabilir.
    func toggleFollow(userToToggle: User) async {
        guard let currentUserId = self.currentUserId, currentUserId != userToToggle.id else { return }
        
        let targetUserId = userToToggle.id
        let isCurrentlyFollowing = followStatus[targetUserId] ?? false
        
        followStatus[targetUserId] = !isCurrentlyFollowing
        
        do {
            let followingRef = db.collection("following").document(currentUserId)
            let followersRef = db.collection("followers").document(targetUserId)
            
            if isCurrentlyFollowing {
                try await followingRef.updateData(["users": FieldValue.arrayRemove([targetUserId])])
                try await followersRef.updateData(["users": FieldValue.arrayRemove([currentUserId])])
            } else {
                try await followingRef.setData(["users": FieldValue.arrayUnion([targetUserId])], merge: true)
                try await followersRef.setData(["users": FieldValue.arrayUnion([currentUserId])], merge: true)
            }
        } catch {
            print("❌ Takip toggle hatası: \(error.localizedDescription)")
            followStatus[targetUserId] = isCurrentlyFollowing
        }
    }
} 
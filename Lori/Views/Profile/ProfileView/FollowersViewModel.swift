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
            // 1. Görüntülenen kullanıcının dokümanını 'users' koleksiyonundan al
            let userDoc = try await db.collection("users").document(userId).getDocument()
            guard let userData = userDoc.data(), userDoc.exists else {
                print("❌ Takipçileri yüklerken kullanıcı dokümanı bulunamadı veya boş: \(userId)")
                self.followers = []
                await checkFollowStatus(for: [])
                return
            }
            // Kullanıcının 'followers' dizisini oku
            let followerIds = userData["followers"] as? [String] ?? []
            
            guard !followerIds.isEmpty else {
                self.followers = []
                await checkFollowStatus(for: [])
                return
            }
            
            // 2. Takipçi kullanıcı bilgilerini 'users' koleksiyonundan al (Chunking ile)
            var loadedFollowers: [User] = []
            let chunks = followerIds.chunked(into: 10)
            
            for chunk in chunks {
                let querySnapshot = try await db.collection("users").whereField(FieldPath.documentID(), in: chunk).getDocuments()
                for document in querySnapshot.documents {
                    let data = document.data()
                    let id = document.documentID
                    let username = data["username"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let profileImageUrl = data["profileImageUrl"] as? String
                    let bio = data["bio"] as? String
                    let createdAtTimestamp = data["createdAt"] as? Timestamp
                    let createdAtDate = createdAtTimestamp?.dateValue() ?? Date()
                    let isVerified = data["isVerified"] as? Bool ?? false
                    let usernameLower = data["usernameLower"] as? String ?? username.lowercased()
                    
                    let user = User(
                        id: id,
                        username: username,
                        email: email,
                        profileImageUrl: profileImageUrl,
                        bio: bio,
                        followers: 0,
                        following: 0,
                        createdAt: createdAtDate,
                        isVerified: isVerified,
                        usernameLower: usernameLower
                    )
                    loadedFollowers.append(user)
                }
            }
            self.followers = loadedFollowers
            
            // 3. Mevcut kullanıcının takip durumlarını kontrol et (Bu listedeki kişileri takip ediyor mu?)
            await checkFollowStatus(for: followerIds)
            
        } catch {
            print("❌ Takipçi yükleme hatası: \(error.localizedDescription)")
            self.followers = []
        }
    }
    
    private func checkFollowStatus(for userIds: [String]) async {
        guard let currentUserId = self.currentUserId else { return }
        
        if userIds.isEmpty {
            DispatchQueue.main.async { self.followStatus = [:] }
            return
        }
        
        do {
            // Mevcut kullanıcının dokümanını 'users' koleksiyonundan al
            let currentUserDoc = try await db.collection("users").document(currentUserId).getDocument()
            guard let currentUserData = currentUserDoc.data(), currentUserDoc.exists else {
                print("❌ Takip durumu kontrolü için mevcut kullanıcı dokümanı bulunamadı: \(currentUserId)")
                DispatchQueue.main.async { self.followStatus = [:] }
                return
            }
            // Mevcut kullanıcının 'following' dizisini oku
            let currentlyFollowingIds = Set(currentUserData["following"] as? [String] ?? [])
            
            var statusMap: [String: Bool] = [:]
            for id in userIds {
                statusMap[id] = currentlyFollowingIds.contains(id)
            }
            DispatchQueue.main.async {
                self.followStatus = statusMap
            }
        } catch {
            print("❌ Takip durumu kontrol hatası: \(error.localizedDescription)")
            DispatchQueue.main.async { self.followStatus = [:] }
        }
    }
    
    func toggleFollow(userToToggle: User) async {
        guard let currentUserId = self.currentUserId, currentUserId != userToToggle.id else { return }
        
        let targetUserId = userToToggle.id
        let isCurrentlyFollowing = followStatus[targetUserId] ?? false
        
        // İyimser UI güncellemesi
        DispatchQueue.main.async {
            self.followStatus[targetUserId] = !isCurrentlyFollowing
        }
        
        do {
            let currentUserRef = db.collection("users").document(currentUserId)
            let targetUserRef = db.collection("users").document(targetUserId)
            
            // Firestore transaction kullanarak 'users' koleksiyonunu atomik olarak güncelle
            try await db.runTransaction { (transaction, errorPointer) -> Any? in
                // Mevcut kullanıcının 'following' listesini güncelle
                if isCurrentlyFollowing {
                    transaction.updateData(["following": FieldValue.arrayRemove([targetUserId])], forDocument: currentUserRef)
                } else {
                    transaction.updateData(["following": FieldValue.arrayUnion([targetUserId])], forDocument: currentUserRef)
                }
                
                // Hedef kullanıcının 'followers' listesini güncelle
                if isCurrentlyFollowing {
                    transaction.updateData(["followers": FieldValue.arrayRemove([currentUserId])], forDocument: targetUserRef)
                } else {
                    transaction.updateData(["followers": FieldValue.arrayUnion([currentUserId])], forDocument: targetUserRef)
                }
                return nil
            }
            print("✅ Takip durumu (users collection) başarıyla güncellendi: \(targetUserId)")
            
        } catch {
            print("❌ Takip toggle (users collection) hatası: \(error.localizedDescription)")
            // Hata durumunda UI'ı eski haline getir
            DispatchQueue.main.async {
                self.followStatus[targetUserId] = isCurrentlyFollowing
            }
        }
    }
}

// Array chunked extension (Artık ortak dosyada tanımlı olduğu için kaldırılıyor)
/*
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
*/

// Opsiyonel: Kullanıcının takipçi/takip edilen sayılarını güncellemek için fonksiyon
/*
private func updateUserFollowCounts(userId: String) async { ... }
*/ 
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
    private let inAppNotificationService = InAppNotificationService.shared
    
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
            // 1. Görüntülenen kullanıcının dokümanını 'users' koleksiyonundan al
            let userDoc = try await db.collection("users").document(userId).getDocument()
            guard let userData = userDoc.data(), userDoc.exists else {
                print("❌ Takip edilenleri yüklerken kullanıcı dokümanı bulunamadı veya boş: \(userId)")
                self.following = []
                await checkFollowStatus(for: []) // Durumu temizle
                return
            }
            // Kullanıcının 'following' dizisini oku
            let followingIds = userData["following"] as? [String] ?? []
            
            guard !followingIds.isEmpty else {
                self.following = []
                await checkFollowStatus(for: []) // Durumu temizle
                return
            }
            
            // 2. Takip edilen kullanıcı bilgilerini 'users' koleksiyonundan al (Chunking ile)
            var loadedFollowing: [User] = []
            let chunks = followingIds.chunked(into: 10)
            
            for chunk in chunks {
                let querySnapshot = try await db.collection("users").whereField(FieldPath.documentID(), in: chunk).getDocuments()
                for document in querySnapshot.documents {
                    // MANUEL DÖNÜŞÜM: document.data(as: User.self) yerine
                    let data = document.data()
                    let id = document.documentID
                    let username = data["username"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let profileImageUrl = data["profileImageUrl"] as? String
                    let bio = data["bio"] as? String
                    let createdAtTimestamp = data["createdAt"] as? Timestamp
                    let createdAtDate = createdAtTimestamp?.dateValue() ?? Date() // Timestamp'ı Date'e çevir
                    let isVerified = data["isVerified"] as? Bool ?? false
                    let usernameLower = data["usernameLower"] as? String ?? username.lowercased()
                    
                    // User nesnesini manuel oluştur, followers/following için 0 kullan
                    let user = User(
                        id: id,
                        username: username,
                        email: email,
                        profileImageUrl: profileImageUrl,
                        bio: bio,
                        followers: 0, // Varsayılan değer veya liste için gereksizse 0
                        following: 0, // Varsayılan değer veya liste için gereksizse 0
                        createdAt: createdAtDate,
                        isVerified: isVerified,
                        usernameLower: usernameLower
                    )
                    loadedFollowing.append(user)
                }
            }
            self.following = loadedFollowing
            
            // 3. Mevcut kullanıcının takip durumlarını kontrol et
            await checkFollowStatus(for: followingIds)
            
        } catch {
            print("❌ Takip edilen yükleme hatası: \(error.localizedDescription)")
            self.following = [] // Hata durumunda listeyi temizle
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
            // Mevcut kullanıcının 'following' dizisini oku ve Set'e çevir
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
                // İşlem sırasında dokümanların varlığını kontrol etmeye gerek yok,
                // arrayUnion/arrayRemove var olmayan alanları/dokümanları tolere eder.
                
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
            
            // In-app notification oluştur (sadece takip ettiğinde)
            if !isCurrentlyFollowing {
                Task {
                    do {
                        // Takip eden kullanıcının bilgilerini al
                        let userDoc = try await db.collection("users").document(currentUserId).getDocument()
                        if let userData = userDoc.data(),
                           let senderName = userData["username"] as? String {
                            inAppNotificationService.createFollowNotification(
                                for: targetUserId,
                                from: currentUserId,
                                senderName: senderName
                            )
                        }
                    } catch {
                        print("In-app notification oluşturulamadı: \(error)")
                    }
                }
            }
            
            // Profildeki takipçi/takip edilen sayılarını da güncellemek önemli olabilir.
            // Bu genellikle ana profil viewmodel'inde veya Cloud Function ile yapılır.
            
        } catch {
            print("❌ Takip toggle (users collection) hatası: \(error.localizedDescription)")
            // Hata durumunda UI'ı eski haline getir
            DispatchQueue.main.async {
                self.followStatus[targetUserId] = isCurrentlyFollowing
            }
        }
    }
    
    // Opsiyonel: Kullanıcının takipçi/takip edilen sayılarını güncellemek için fonksiyon
    /*
    private func updateUserFollowCounts(userId: String) async {
        // Bu fonksiyon, ilgili 'followers' ve 'following' dokümanlarındaki 'users' dizisinin boyutunu alıp
        // 'users' koleksiyonundaki ilgili kullanıcının 'followerCount' ve 'followingCount' alanlarını güncelleyebilir.
        // Bu işlem genellikle Cloud Functions ile daha verimli yönetilir.
    }
    */
}

// Array extension kaldırıldı - Array+Chunked.swift dosyası kullanılıyor 

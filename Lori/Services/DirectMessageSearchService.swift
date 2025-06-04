import Foundation
import Firebase
import FirebaseFirestore

class DirectMessageSearchService: ObservableObject {
    static let shared = DirectMessageSearchService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // Kullanıcıları kullanıcı adına göre ara
    func searchUsers(with searchText: String, limit: Int = 20) async throws -> [User] {
        print("🔍 DirectMessageSearchService.searchUsers çağrıldı - Arama metni: '\(searchText)', Limit: \(limit)")
        
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ Arama metni boş, arama iptal edildi")
            return []
        }

        let lowercaseSearch = searchText.lowercased()
        print("📝 Küçük harfe çevrilmiş arama metni: '\(lowercaseSearch)'")
        
        var allUsers: [User] = []
        
        // 1. Direkt userId ile arama
        print("[DirectMessageSearchService] Firestore'da userId ile arama başlatılıyor: \(searchText)")
        if let userByIdSnapshot = try? await db.collection("users").document(searchText).getDocument(),
           userByIdSnapshot.exists {
            let data = userByIdSnapshot.data() ?? [:]
            let usernameLower = data["usernameLower"] as? String ?? (data["username"] as? String ?? "").lowercased()
            let userById = User(
                id: userByIdSnapshot.documentID,
                username: data["username"] as? String ?? "",
                email: data["email"] as? String ?? "",
                profileImageUrl: data["profileImageUrl"] as? String,
                bio: data["bio"] as? String,
                followers: data["followers"] as? Int ?? 0,
                following: data["following"] as? Int ?? 0,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                isVerified: data["isVerified"] as? Bool ?? false,
                usernameLower: usernameLower
            )
            if userById.isValid {
                allUsers.append(userById)
                print("[DirectMessageSearchService] Firestore userId ile eşleşen kullanıcı bulundu: \(userById.username)")
            }
        }
        
        // 2. usernameLower ile arama
        print("[DirectMessageSearchService] Firestore'da usernameLower ile arama başlatılıyor: \(lowercaseSearch)")
        let usernameQuery = try await db.collection("users")
            .whereField("usernameLower", isGreaterThanOrEqualTo: lowercaseSearch)
            .whereField("usernameLower", isLessThanOrEqualTo: lowercaseSearch + "\u{f8ff}")
            .limit(to: limit)
            .getDocuments()
        
        print("[DirectMessageSearchService] Firestore usernameLower arama sonucu: \(usernameQuery.documents.count) kullanıcı")
        let usernameUsers = usernameQuery.documents.compactMap { document -> User? in
            let data = document.data()
            let usernameLower = data["usernameLower"] as? String ?? (data["username"] as? String ?? "").lowercased()
            let user = User(
                id: document.documentID,
                username: data["username"] as? String ?? "",
                email: data["email"] as? String ?? "",
                profileImageUrl: data["profileImageUrl"] as? String,
                bio: data["bio"] as? String,
                followers: data["followers"] as? Int ?? 0,
                following: data["following"] as? Int ?? 0,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                isVerified: data["isVerified"] as? Bool ?? false,
                usernameLower: usernameLower
            )
            return user.isValid ? user : nil
        }
        
        // 3. Email ile arama
        print("[DirectMessageSearchService] Firestore'da email ile arama başlatılıyor: \(lowercaseSearch)")
        let emailQuery = try await db.collection("users")
            .whereField("email", isGreaterThanOrEqualTo: lowercaseSearch)
            .whereField("email", isLessThanOrEqualTo: lowercaseSearch + "\u{f8ff}")
            .limit(to: limit/2)
            .getDocuments()
        
        print("[DirectMessageSearchService] Firestore email arama sonucu: \(emailQuery.documents.count) kullanıcı")
        let emailUsers = emailQuery.documents.compactMap { document -> User? in
            let data = document.data()
            let usernameLower = data["usernameLower"] as? String ?? (data["username"] as? String ?? "").lowercased()
            let user = User(
                id: document.documentID,
                username: data["username"] as? String ?? "",
                email: data["email"] as? String ?? "",
                profileImageUrl: data["profileImageUrl"] as? String,
                bio: data["bio"] as? String,
                followers: data["followers"] as? Int ?? 0,
                following: data["following"] as? Int ?? 0,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                isVerified: data["isVerified"] as? Bool ?? false,
                usernameLower: usernameLower
            )
            return user.isValid ? user : nil
        }
        
        // Tüm kullanıcıları birleştir
        allUsers.append(contentsOf: usernameUsers)
        allUsers.append(contentsOf: emailUsers)
        
        // Aynı kullanıcıları tekil hale getir
        var uniqueUsers: [User] = []
        var seenIds: Set<String> = []
        for user in allUsers {
            if !seenIds.contains(user.id) {
                uniqueUsers.append(user)
                seenIds.insert(user.id)
            }
        }
        
        // Sonuçları sırala - arama metniyle tam eşleşenleri ve önce başlayanları öne çıkart
        uniqueUsers.sort { user1, user2 in
            let search = lowercaseSearch
            let username1 = user1.username.lowercased()
            let username2 = user2.username.lowercased()
            
            if username1 == search && username2 != search { return true }
            if username2 == search && username1 != search { return false }
            if username1.hasPrefix(search) && !username2.hasPrefix(search) { return true }
            if username2.hasPrefix(search) && !username1.hasPrefix(search) { return false }
            return user1.followers > user2.followers
        }
        
        print("[DirectMessageSearchService] Arama tamamlandı, sonuç sayısı: \(uniqueUsers.count)")
        return Array(uniqueUsers.prefix(limit))
    }
    
    // Kullanıcının takip ettiği kişileri getir
    func fetchUserFollowing(for userId: String, limit: Int = 10) async throws -> [User] {
        let querySnapshot = try await db.collection("follows")
            .whereField("followerId", isEqualTo: userId)
            .limit(to: limit)
            .getDocuments()
        
        var userIds: [String] = []
        for document in querySnapshot.documents {
            if let followingId = document.data()["followingId"] as? String {
                userIds.append(followingId)
            }
        }
        
        // Kullanıcı bilgilerini getir
        var users: [User] = []
        for id in userIds {
            let userDoc = try await db.collection("users").document(id).getDocument()
            if let user = try? userDoc.data(as: User.self) {
                // Kullanıcının geçerli veriye sahip olup olmadığını kontrol et
                guard user.isValid else {
                    print("Geçersiz kullanıcı verisi atlandı - UserID: \(user.id), Username: \(user.username)")
                    continue
                }
                
                users.append(user)
            }
        }
        
        return users
    }
    
    // En çok etkileşime girilen kullanıcıları getir
    func fetchMostInteractedUsers(for userId: String, limit: Int = 10) async throws -> [User] {
        // Kullanıcının etkileşimlerini getir (beğeniler, yorumlar)
        let interactionsSnapshot = try await db.collection("userEmotionInteractions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 100) // Son 100 etkileşimi al
            .getDocuments()
        
        // Post ID'lerini topla
        var postIds: [String] = []
        for document in interactionsSnapshot.documents {
            if let postId = document.data()["postId"] as? String {
                postIds.append(postId)
            }
        }
        
        // Post sahiplerini bul ve etkileşim sayısına göre sırala
        var userInteractionCounts: [String: Int] = [:]
        
        for postId in postIds {
            let postDoc = try await db.collection("posts").document(postId).getDocument()
            if let authorId = postDoc.data()?["authorId"] as? String, authorId != userId {
                userInteractionCounts[authorId, default: 0] += 1
            }
        }
        
        // En çok etkileşime girilen kullanıcıları sırala
        let sortedUserIds = userInteractionCounts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
        
        // Kullanıcı bilgilerini getir
        var users: [User] = []
        for userId in sortedUserIds {
            let userDoc = try await db.collection("users").document(userId).getDocument()
            if let user = try? userDoc.data(as: User.self) {
                // Kullanıcının geçerli veriye sahip olup olmadığını kontrol et
                guard user.isValid else {
                    print("Geçersiz kullanıcı verisi atlandı - UserID: \(user.id), Username: \(user.username)")
                    continue
                }
                
                users.append(user)
            }
        }
        
        return users
    }
    
    // Tek bir kullanıcının bilgisini getir
    func fetchUser(by userId: String) async throws -> User {
        print("[DirectMessageSearchService] fetchUser çağrıldı - userId: \(userId)")
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if !document.exists {
                print("[DirectMessageSearchService] Kullanıcı dokümanı bulunamadı - userId: \(userId)")
                throw NSError(
                    domain: "DirectMessageSearchService", 
                    code: 2, 
                    userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı (ID: \(userId))"]
                )
            }
            
            guard let data = document.data() else {
                print("[DirectMessageSearchService] Kullanıcı verisi boş - userId: \(userId)")
                throw NSError(
                    domain: "DirectMessageSearchService", 
                    code: 3, 
                    userInfo: [NSLocalizedDescriptionKey: "Kullanıcı verisi boş (ID: \(userId))"]
                )
            }
            
            let usernameLower = data["usernameLower"] as? String ?? (data["username"] as? String ?? "").lowercased()
            let user = User(
                id: document.documentID,
                username: data["username"] as? String ?? "Bilinmeyen",
                email: data["email"] as? String ?? "",
                profileImageUrl: data["profileImageUrl"] as? String,
                bio: data["bio"] as? String,
                followers: data["followers"] as? Int ?? 0,
                following: data["following"] as? Int ?? 0,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                isVerified: data["isVerified"] as? Bool ?? false,
                usernameLower: usernameLower
            )
            
            if !user.isValid {
                print("[DirectMessageSearchService] Geçersiz kullanıcı verisi - userId: \(userId)")
                throw NSError(
                    domain: "DirectMessageSearchService", 
                    code: 4, 
                    userInfo: [NSLocalizedDescriptionKey: "Geçersiz kullanıcı verisi (ID: \(userId))"]
                )
            }
            
            print("[DirectMessageSearchService] Kullanıcı başarıyla getirildi - userId: \(userId), username: \(user.username)")
            return user
        } catch let error as NSError {
            if error.domain == "DirectMessageSearchService" {
                // Bizim tanımladığımız hataları tekrar fırlat
                throw error
            } else {
                // Firestore hatalarını sararak daha anlaşılır hale getir
                print("[DirectMessageSearchService] Firestore hatası - userId: \(userId), error: \(error.localizedDescription)")
                throw NSError(
                    domain: "DirectMessageSearchService", 
                    code: 1, 
                    userInfo: [NSLocalizedDescriptionKey: "Firestore'dan kullanıcı bilgisi getirilemedi: \(error.localizedDescription)"]
                )
            }
        }
    }
} 
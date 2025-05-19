import Foundation
import Firebase
import FirebaseFirestore

class DirectMessageService: ObservableObject {
    @Published var conversations: [DirectMessageConversation] = []
    @Published var messages: [DirectMessage] = []
    
    private let db = Firestore.firestore()
    
    // Tüm konuşma listesini getir
    func fetchUserConversations(for userId: String) async throws -> [DirectMessageConversation] {
        let querySnapshot = try await db.collection("conversations")
            .whereField("users", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true)
            .getDocuments()
        
        var conversations: [DirectMessageConversation] = []
        for document in querySnapshot.documents {
            let conversation = try document.data(as: DirectMessageConversation.self)
            conversations.append(conversation)
        }
        
        return conversations
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
                users.append(user)
            }
        }
        
        return users
    }
    
    // Kullanıcıları kullanıcı adına göre ara
    func searchUsers(with searchText: String, limit: Int = 10) async throws -> [User] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let querySnapshot = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: searchText)
            .whereField("username", isLessThanOrEqualTo: searchText + "\\uf8ff") // Firestore'da prefix arama için
            .limit(to: limit)
            .getDocuments()

        var searchedUsers: [User] = []
        for document in querySnapshot.documents {
            if let user = try? document.data(as: User.self) {
                searchedUsers.append(user)
            }
        }
        return searchedUsers
    }
    
    // Belirli bir konuşmaya ait mesajları getir
    func fetchMessages(for conversationId: String) async throws -> [DirectMessage] {
        let querySnapshot = try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        var messages: [DirectMessage] = []
        for document in querySnapshot.documents {
            let message = try document.data(as: DirectMessage.self)
            messages.append(message)
        }
        
        return messages
    }
    
    // Yeni mesaj gönder
    func sendMessage(to conversationId: String, message: DirectMessage) async throws {
        if let messageId = message.id, !messageId.isEmpty {
            // ID zaten varsa belirli bir doküman ID'sini kullan
            try db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .document(messageId)
                .setData(from: message)
        } else {
            // Yeni bir doküman ID'si oluştur
            _ = try db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .addDocument(from: message)
        }
        
        // Son mesajı güncelle
        try await db.collection("conversations").document(conversationId).updateData([
            "lastMessage": message.content,
            "lastMessageTimestamp": message.timestamp,
            "lastMessageSenderId": message.senderId,
            "lastMessageRead": false
        ])
    }
    
    // Yeni konuşma oluştur
    func createConversation(between userIds: [String], initialMessage: String?, senderId: String) async throws -> String {
        guard userIds.count == 2 else {
            throw NSError(domain: "DirectMessageService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Konuşma iki kullanıcı arasında olmalıdır"])
        }
        
        let sortedUserIds = userIds.sorted() // Kullanıcı ID'lerini sıralayarak her zaman aynı sorgu sonucunu almayı garantile

        // Konuşmanın daha önce var olup olmadığını kontrol et
        let querySnapshot = try await db.collection("conversations")
            .whereField("users", isEqualTo: sortedUserIds) // Sıralı ID'leri kullan
            .getDocuments()
        
        if let existingDoc = querySnapshot.documents.first, let conversationId = existingDoc.documentID as String? {
            // Konuşma zaten varsa ve bir başlangıç mesajı varsa, sadece son mesajı güncelle
            if let messageContent = initialMessage, !messageContent.isEmpty {
                 try await db.collection("conversations").document(conversationId).updateData([
                    "lastMessage": messageContent,
                    "lastMessageTimestamp": Date(),
                    "lastMessageSenderId": senderId,
                    "lastMessageRead": false // Yeni mesaj olduğu için okunmadı olarak ayarla
                ])
                
                // Mesajı da ekle
                let message = DirectMessage(
                    id: nil,
                    senderId: senderId,
                    receiverId: sortedUserIds.first(where: { $0 != senderId }) ?? "",
                    content: messageContent,
                    timestamp: Date(),
                    isRead: false,
                    imageURL: nil
                )
                _ = try db.collection("conversations")
                    .document(conversationId)
                    .collection("messages")
                    .addDocument(from: message)
            }
            return conversationId
        }
        
        // Yeni konuşma oluştur
        let conversation = DirectMessageConversation(
            id: nil,
            users: sortedUserIds, // Sıralı ID'leri kullan
            lastMessage: initialMessage ?? "Sohbet başlatıldı.", // Başlangıç mesajı yoksa varsayılan bir metin
            lastMessageTimestamp: Date(),
            lastMessageSenderId: senderId, // Başlangıç mesajı yoksa bile gönderen ID'si gerekli olabilir
            lastMessageRead: false, // Her zaman false olarak başlar
            createdAt: Date() // Konuşmanın oluşturulma zamanı
        )
        
        let docRef = try db.collection("conversations").addDocument(from: conversation)
        
        // Eğer bir başlangıç mesajı varsa, onu da ekle
        if let messageContent = initialMessage, !messageContent.isEmpty {
            let message = DirectMessage(
                id: nil,
                senderId: senderId,
                receiverId: sortedUserIds.first(where: { $0 != senderId }) ?? "",
                content: messageContent,
                timestamp: Date(),
                isRead: false,
                imageURL: nil
            )
            
            try db.collection("conversations")
                .document(docRef.documentID)
                .collection("messages")
                .addDocument(from: message)
        }
        
        return docRef.documentID
    }
    
    // Mesajları okundu olarak işaretle
    func markMessagesAsRead(in conversationId: String, for userId: String) async throws {
        let querySnapshot = try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        let batch = db.batch()
        for document in querySnapshot.documents {
            let docRef = document.reference
            batch.updateData(["isRead": true], forDocument: docRef)
        }
        
        try await batch.commit()
        
        // Konuşmadaki son mesaj kullanıcıya aitse son mesajı okudu olarak işaretle
        let conversationDoc = try await db.collection("conversations").document(conversationId).getDocument()
        if let conversation = try? conversationDoc.data(as: DirectMessageConversation.self),
           conversation.lastMessageSenderId != userId {
            try await db.collection("conversations").document(conversationId).updateData([
                "lastMessageRead": true
            ])
        }
    }
    
    // Konuşmayı sil
    func deleteConversation(_ conversationId: String) async throws {
        // Önce tüm mesajları sil
        let messagesSnapshot = try await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .getDocuments()
        
        let batch = db.batch()
        for document in messagesSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        
        // Sonra konuşmayı sil
        batch.deleteDocument(db.collection("conversations").document(conversationId))
        
        try await batch.commit()
    }
} 

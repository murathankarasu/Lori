import Foundation
import FirebaseFirestore

public class UserEmotionService {
    static let shared = UserEmotionService()
    private let db = Firestore.firestore()
    
    func saveInteraction(userId: String, postId: String, interactionType: UserEmotionInteraction.InteractionType, emotion: String, confidence: Double) async throws {
        let interaction = UserEmotionInteraction(
            userId: userId,
            postId: postId,
            interactionType: interactionType,
            emotion: emotion,
            confidence: confidence
        )
        
        let interactionData: [String: Any] = [
            "userId": interaction.userId,
            "postId": interaction.postId,
            "interactionType": interaction.interactionType.rawValue,
            "emotion": interaction.emotion,
            "confidence": interaction.confidence,
            "timestamp": Timestamp(date: interaction.timestamp)
        ]
        
        try await db.collection("userEmotionInteractions").addDocument(data: interactionData)
        
        print("\n=== Etkileşim Kaydedildi ===")
        print("Kullanıcı ID: \(userId)")
        print("Gönderi ID: \(postId)")
        print("Etkileşim Türü: \(interactionType.rawValue)")
        print("Duygu: \(emotion)")
        print("Güven: \(confidence)")
        print("===================\n")
    }
    
    func getInteractions(userId: String) async throws -> [UserEmotionInteraction] {
        let snapshot = try await db.collection("userEmotionInteractions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document -> UserEmotionInteraction? in
            let data = document.data()
            guard let userId = data["userId"] as? String,
                  let postId = data["postId"] as? String,
                  let interactionTypeString = data["interactionType"] as? String,
                  let interactionType = UserEmotionInteraction.InteractionType(rawValue: interactionTypeString),
                  let emotion = data["emotion"] as? String,
                  let confidence = data["confidence"] as? Double,
                  let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                return nil
            }
            
            return UserEmotionInteraction(
                userId: userId,
                postId: postId,
                interactionType: interactionType,
                emotion: emotion,
                confidence: confidence,
                timestamp: timestamp
            )
        }
    }
    
    /// Kullanıcıya topluluk rozeti verilmeli mi?
    /// - Parameter userId: Rozet kontrolü yapılacak kullanıcı
    /// - Returns: Bool (rozet verilmeli mi?)
    func hasCommunityBadge(userId: String) async throws -> Bool {
        // 1. Kullanıcının tüm postlarını çek
        let postsSnapshot = try await db.collection("posts").whereField("userId", isEqualTo: userId).getDocuments()
        let postIds = postsSnapshot.documents.compactMap { $0.documentID }
        if postIds.isEmpty { return false }

        // 2. postIds'i 30'luk parçalara böl
        let batchSize = 30
        var allInteractions: [UserEmotionInteraction] = []
        let positiveEmotions = ["Joy", "Love", "Surprise"]

        for batch in stride(from: 0, to: postIds.count, by: batchSize) {
            let end = min(batch + batchSize, postIds.count)
            let batchIds = Array(postIds[batch..<end])
            let interactionsSnapshot = try await db.collection("userEmotionInteractions")
                .whereField("postId", in: batchIds)
                .getDocuments()
            let interactions = interactionsSnapshot.documents.compactMap { doc -> UserEmotionInteraction? in
                let data = doc.data()
                guard let postId = data["postId"] as? String,
                      let interactionTypeString = data["interactionType"] as? String,
                      let interactionType = UserEmotionInteraction.InteractionType(rawValue: interactionTypeString),
                      let emotion = data["emotion"] as? String else { return nil }
                return UserEmotionInteraction(
                    userId: data["userId"] as? String ?? "",
                    postId: postId,
                    interactionType: interactionType,
                    emotion: emotion,
                    confidence: data["confidence"] as? Double ?? 0.0,
                    timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
            allInteractions.append(contentsOf: interactions)
        }

        // 3. Pozitif etkileşimleri filtrele (sadece son 1 ay)
        let oneMonthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
        let positiveInteractions = allInteractions.filter { interaction in
            (interaction.interactionType == .like || interaction.interactionType == .comment) &&
            positiveEmotions.contains(where: { interaction.emotion.localizedCaseInsensitiveContains($0) }) &&
            interaction.timestamp >= oneMonthAgo
        }

        // 4. 3 veya daha fazla pozitif etkileşim varsa rozet ver
        return positiveInteractions.count >= 3
    }
} 
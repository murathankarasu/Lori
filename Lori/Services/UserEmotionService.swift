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
} 
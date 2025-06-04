import Foundation
import FirebaseFirestore
import FirebaseAuth

class InteractionService {
    static let shared = InteractionService()
    private let db = Firestore.firestore()
    private let emotionService = EmotionService.shared
    private let userEmotionService = UserEmotionService.shared
    private let notificationService = NotificationService.shared
    private let inAppNotificationService = InAppNotificationService.shared
    
    private init() {}
    
    // MARK: - Like İşlemleri
    
    /// Post beğeni durumunu değiştirir (beğeni ekler veya kaldırır)
    /// - Parameters:
    ///   - post: Beğeni yapılacak post
    ///   - isLiked: Mevcut beğeni durumu (true: beğenilmiş, false: beğenilmemiş)
    ///   - completion: İşlem tamamlandığında çağrılacak closure
    func toggleLike(for post: Post, isLiked: Bool, completion: @escaping (Bool, Error?) -> Void) {
        guard let postId = post.id,
              let userId = Auth.auth().currentUser?.uid else {
            completion(isLiked, NSError(domain: "InteractionService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User session required"]))
            return
        }
        
        let likeRef = db.collection("posts")
            .document(postId)
            .collection("likes")
            .document(userId)
        let postRef = db.collection("posts").document(postId)
        
        if isLiked {
            // Remove like
            likeRef.delete { error in
                if let error = error {
                    completion(isLiked, error)
                    return
                }
                
                // Decrease like count
                postRef.updateData(["likes": FieldValue.increment(Int64(-1))]) { error in
                    if let error = error {
                        completion(isLiked, error)
                        return
                    }
                    
                    // Record dislike interaction
                    Task {
                        do {
                            // Use post's current emotion or create random emotion
                            let emotion: String
                            let confidence: Double
                            
                            if let postEmotion = post.emotionAnalysis {
                                emotion = postEmotion.emotion
                                confidence = postEmotion.confidence
                            } else {
                                // Generate random emotion
                                let emotions = ["joy", "fear", "anger", "love", "sadness", "surprise"]
                                emotion = emotions.randomElement() ?? "joy"
                                confidence = Double.random(in: 0.6...0.9)
                            }
                            
                            try await self.userEmotionService.saveInteraction(
                                userId: userId,
                                postId: postId,
                                interactionType: .dislike,
                                emotion: emotion,
                                confidence: confidence
                            )
                            // Operation completed successfully
                            await MainActor.run {
                                completion(!isLiked, nil)
                            }
                        } catch {
                            print("Dislike interaction could not be saved: \(error)")
                            // Even if there's an error, the unlike operation should be completed
                            await MainActor.run {
                                completion(!isLiked, nil)
                            }
                        }
                    }
                }
            }
        } else {
            // Add like
            likeRef.setData([:]) { error in
                if let error = error {
                    completion(isLiked, error)
                    return
                }
                
                // Increase like count
                postRef.updateData(["likes": FieldValue.increment(Int64(1))]) { error in
                    if let error = error {
                        completion(isLiked, error)
                        return
                    }
                    
                    // Record interaction
                    Task {
                        do {
                            // Use post's current emotion or create random emotion
                            let emotion: String
                            let confidence: Double
                            
                            if let postEmotion = post.emotionAnalysis {
                                emotion = postEmotion.emotion
                                confidence = postEmotion.confidence
                            } else {
                                // Generate random emotion
                                let emotions = ["joy", "fear", "anger", "love", "sadness", "surprise"]
                                emotion = emotions.randomElement() ?? "joy"
                                confidence = Double.random(in: 0.6...0.9)
                            }
                            
                            try await self.userEmotionService.saveInteraction(
                                userId: userId,
                                postId: postId,
                                interactionType: .like,
                                emotion: emotion,
                                confidence: confidence
                            )
                            
                            // Send like notification (only if not liking own post)
                            print("🔔 DEBUG: Checking if should send like notification")
                            print("   - Post author ID: '\(post.userId)'")
                            print("   - Current user ID: '\(userId)'")
                            print("   - Post ID: '\(postId)'")
                            print("   - Are they different? \(post.userId != userId)")
                            
                            if post.userId != userId {
                                print("🔔 DEBUG: ✅ SENDING like notification")
                                print("   - FROM: \(userId)")
                                print("   - TO: \(post.userId)")
                                
                                self.notificationService.sendSocialNotification(
                                    type: .like,
                                    from: userId,
                                    to: post.userId,
                                    postId: postId
                                )
                                
                                // Create in-app notification
                                Task {
                                    do {
                                        // Get information of the user who liked
                                        let userDoc = try await self.db.collection("users").document(userId).getDocument()
                                        if let userData = userDoc.data(),
                                           let senderName = userData["username"] as? String {
                                            print("   - Sender name: \(senderName)")
                                            print("   - Creating in-app notification for TARGET user: \(post.userId)")
                                            
                                            self.inAppNotificationService.createLikeNotification(
                                                for: post.userId,
                                                from: userId,
                                                senderName: senderName,
                                                postId: postId
                                            )
                                        }
                                    } catch {
                                        print("In-app notification could not be created: \(error)")
                                    }
                                }
                            } else {
                                print("🔔 DEBUG: ❌ NOT sending notification - user is liking their own post")
                                print("   - Both IDs are: \(userId)")
                            }
                            
                            // Operation completed successfully
                            await MainActor.run {
                                completion(!isLiked, nil)
                            }
                        } catch {
                            print("Like interaction could not be saved: \(error)")
                            // Even if there's an error, the like operation should be completed
                            await MainActor.run {
                                completion(!isLiked, nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Beğeni Dinleme İşlemleri
    
    /// Bir postun beğeni sayısını ve kullanıcının beğeni durumunu dinler
    /// - Parameters:
    ///   - postId: Post ID
    ///   - onUpdate: Güncelleme olduğunda çağrılacak closure
    /// - Returns: Dinleyici kaydı (remove() için kullanılabilir)
    func listenToLikes(for postId: String, onUpdate: @escaping (Int, Bool) -> Void) -> ListenerRegistration {
        let likesRef = db.collection("posts")
            .document(postId)
            .collection("likes")
        
        return likesRef.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error occurred while listening to likes: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let likesCount = documents.count
            let userId = Auth.auth().currentUser?.uid ?? ""
            let isLiked = !userId.isEmpty && documents.contains { $0.documentID == userId }
            
            onUpdate(likesCount, isLiked)
        }
    }
    
    // MARK: - Yorum İşlemleri
    
    /// Bir yorum ekler ve etkileşim olarak kaydeder
    /// - Parameters:
    ///   - comment: Eklenecek yorum
    ///   - post: Yorumun ekleneceği post
    ///   - completion: İşlem tamamlandığında çağrılacak closure (Bool: başarılı mı, String?: hata mesajı)
    func addComment(comment: Comment, to post: Post, completion: @escaping (Error?) -> Void) {
        guard let postId = post.id,
              let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "InteractionService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User session required"]))
            return
        }
        
        // Nefret söylemi kontrolü yap
        Task {
            do {
                // Önce yerel kontrol
                let localCheck = HateSpeechService.shared.checkLocalHateSpeech(comment.content)
                if localCheck.containsHateSpeech {
                    await MainActor.run {
                        let error = NSError(domain: "InteractionService", code: 403, userInfo: [
                            NSLocalizedDescriptionKey: "Comments containing hate speech cannot be added",
                            "category": localCheck.category ?? "Hate Speech"
                        ])
                        completion(error)
                    }
                    return
                }
                
                // API üzerinden kontrol
                let response = try await HateSpeechService.shared.checkHateSpeech(text: comment.content)
                // DÜZELTME: API'nin isHateSpeech değerine güvenme, her zaman kategori "1" kontrolü yap
                let isHateSpeech = response.data.category == "1"
                
                if isHateSpeech {
                    await MainActor.run {
                        let error = NSError(domain: "InteractionService", code: 403, userInfo: [
                            NSLocalizedDescriptionKey: "Comments containing hate speech cannot be added",
                            "category": "Hate Speech",
                            "confidence": String(response.data.confidence)
                        ])
                        completion(error)
                    }
                    return
                }
                
                // Nefret söylemi yoksa yorumu ekle
                await saveComment(comment: comment, postId: postId, userId: userId, completion: completion)
                
            } catch {
                print("Hate speech check error: \(error)")
                // Add comment even in case of error (don't block due to API error)
                await saveComment(comment: comment, postId: postId, userId: userId, completion: completion)
            }
        }
    }
    
    /// Yorumu kaydeder ve etkileşimi kaydeder
    /// - Parameters:
    ///   - comment: Kaydedilecek yorum
    ///   - postId: Post ID
    ///   - userId: Kullanıcı ID
    ///   - completion: İşlem tamamlandığında çağrılacak closure
    @MainActor
    private func saveComment(comment: Comment, postId: String, userId: String, completion: @escaping (Error?) -> Void) async {
        let commentRef = db.collection("posts")
            .document(postId)
            .collection("comments")
            .document()
        
        let postRef = db.collection("posts").document(postId)
        
        do {
            // Save comment
            try commentRef.setData(from: comment) { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                // Increase comment count
                postRef.updateData(["comments": FieldValue.increment(Int64(1))]) { error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    // Record interaction and perform emotion analysis
                    Task {
                        do {
                            // Make API call for comment
                            let emotionAnalysis = try await self.emotionService.analyzeEmotion(text: comment.content, operationType: .other)
                            try await self.userEmotionService.saveInteraction(
                                userId: userId,
                                postId: postId,
                                interactionType: .comment,
                                emotion: emotionAnalysis.emotion,
                                confidence: emotionAnalysis.confidence
                            )
                            
                            // Send comment notification to post owner (if not commenting on own post)
                            // Find post owner
                            let postDoc = try await self.db.collection("posts").document(postId).getDocument()
                            if let postData = postDoc.data(),
                               let postAuthorId = postData["userId"] as? String,
                               postAuthorId != userId {
                                self.notificationService.sendSocialNotification(
                                    type: .comment,
                                    from: userId,
                                    to: postAuthorId,
                                    postId: postId
                                )
                                
                                // Create in-app notification
                                Task {
                                    do {
                                        // Get information of the user who commented
                                        let userDoc = try await self.db.collection("users").document(userId).getDocument()
                                        if let userData = userDoc.data(),
                                           let senderName = userData["username"] as? String {
                                            self.inAppNotificationService.createCommentNotification(
                                                for: postAuthorId,
                                                from: userId,
                                                senderName: senderName,
                                                postId: postId
                                            )
                                        }
                                    } catch {
                                        print("In-app notification could not be created: \(error)")
                                    }
                                }
                            }
                            
                            // Operation completed successfully
                            await MainActor.run {
                                completion(nil)
                            }
                        } catch {
                            print("Comment interaction could not be saved: \(error)")
                            // Even if there's an error, the comment should have been added
                            await MainActor.run {
                                completion(nil)
                            }
                        }
                    }
                }
            }
        } catch {
            completion(error)
        }
    }
    
    // MARK: - Yorum Dinleme İşlemleri
    
    /// Bir postun yorumlarını dinler
    /// - Parameters:
    ///   - postId: Post ID
    ///   - onUpdate: Güncelleme olduğunda çağrılacak closure
    /// - Returns: Dinleyici kaydı (remove() için kullanılabilir)
    func listenToComments(for postId: String, onUpdate: @escaping ([Comment]) -> Void) -> ListenerRegistration {
        let commentsRef = db.collection("posts")
            .document(postId)
            .collection("comments")
            .order(by: "timestamp", descending: true)
        
        return commentsRef.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error occurred while listening to comments: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let comments = documents.compactMap { try? $0.data(as: Comment.self) }
            onUpdate(comments)
        }
    }
    
    // MARK: - Görüntüleme Etkileşimi
    
    /// Post görüntüleme etkileşimini kaydeder
    /// - Parameters:
    ///   - post: Görüntülenen post
    func recordViewInteraction(for post: Post) {
        guard let postId = post.id,
              let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        Task {
            do {
                // Post'un mevcut duygusunu kullan veya random duygu oluştur
                let emotion: String
                let confidence: Double
                
                if let postEmotion = post.emotionAnalysis {
                    emotion = postEmotion.emotion
                    confidence = postEmotion.confidence
                } else {
                    // Random duygu oluştur
                    let emotions = ["joy", "fear", "anger", "love", "sadness", "surprise"]
                    emotion = emotions.randomElement() ?? "joy"
                    confidence = Double.random(in: 0.6...0.9)
                }
                
                try await userEmotionService.saveInteraction(
                    userId: userId,
                    postId: postId,
                    interactionType: .viewDetail,
                    emotion: emotion,
                    confidence: confidence
                )
            } catch {
                print("View interaction could not be saved: \(error)")
            }
        }
    }
} 

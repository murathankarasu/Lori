import Foundation
import FirebaseFirestore
import FirebaseAuth

class InteractionService {
    static let shared = InteractionService()
    private let db = Firestore.firestore()
    private let emotionService = EmotionService.shared
    private let userEmotionService = UserEmotionService.shared
    
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
            completion(isLiked, NSError(domain: "InteractionService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı oturumu gerekli"]))
            return
        }
        
        let likeRef = db.collection("posts")
            .document(postId)
            .collection("likes")
            .document(userId)
        let postRef = db.collection("posts").document(postId)
        
        if isLiked {
            // Beğeniyi kaldır
            likeRef.delete { error in
                if let error = error {
                    completion(isLiked, error)
                    return
                }
                
                // Beğeni sayısını azalt
                postRef.updateData(["likes": FieldValue.increment(Int64(-1))]) { error in
                    if let error = error {
                        completion(isLiked, error)
                        return
                    }
                    
                    // Dislike etkileşimini kaydet
                    Task {
                        do {
                            // Dislike için API çağrısı yapmayalım, other olarak işaretleyelim
                            let emotionAnalysis = try await self.emotionService.analyzeEmotion(text: post.content, operationType: .other)
                            try await self.userEmotionService.saveInteraction(
                                userId: userId,
                                postId: postId,
                                interactionType: .dislike,
                                emotion: emotionAnalysis.emotion,
                                confidence: emotionAnalysis.confidence
                            )
                            // İşlem başarıyla tamamlandı
                            await MainActor.run {
                                completion(!isLiked, nil)
                            }
                        } catch {
                            print("Dislike etkileşimi kaydedilemedi: \(error)")
                            // Hata olsa bile beğeniyi kaldırma işlemi tamamlanmış olmalı
                            await MainActor.run {
                                completion(!isLiked, nil)
                            }
                        }
                    }
                }
            }
        } else {
            // Beğeni ekle
            likeRef.setData([:]) { error in
                if let error = error {
                    completion(isLiked, error)
                    return
                }
                
                // Beğeni sayısını artır
                postRef.updateData(["likes": FieldValue.increment(Int64(1))]) { error in
                    if let error = error {
                        completion(isLiked, error)
                        return
                    }
                    
                    // Etkileşimi kaydet ve duygu analizi yap
                    Task {
                        do {
                            // Like için API çağrısı yapalım
                            let emotionAnalysis = try await self.emotionService.analyzeEmotion(text: post.content, operationType: .like)
                            try await self.userEmotionService.saveInteraction(
                                userId: userId,
                                postId: postId,
                                interactionType: .like,
                                emotion: emotionAnalysis.emotion,
                                confidence: emotionAnalysis.confidence
                            )
                            // İşlem başarıyla tamamlandı
                            await MainActor.run {
                                completion(!isLiked, nil)
                            }
                        } catch {
                            print("Beğeni etkileşimi kaydedilemedi: \(error)")
                            // Hata olsa bile beğeni işlemi tamamlanmış olmalı
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
                print("Beğeniler dinlenirken hata oluştu: \(error?.localizedDescription ?? "Bilinmeyen hata")")
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
            completion(NSError(domain: "InteractionService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı oturumu gerekli"]))
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
                            NSLocalizedDescriptionKey: "Nefret söylemi içeren yorum eklenemez",
                            "category": localCheck.category ?? "Nefret Söylemi"
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
                            NSLocalizedDescriptionKey: "Nefret söylemi içeren yorum eklenemez",
                            "category": "Nefret Söylemi",
                            "confidence": String(response.data.confidence)
                        ])
                        completion(error)
                    }
                    return
                }
                
                // Nefret söylemi yoksa yorumu ekle
                await saveComment(comment: comment, postId: postId, userId: userId, completion: completion)
                
            } catch {
                print("Nefret söylemi kontrolü sırasında hata: \(error)")
                // Hata durumunda da yorumu ekle (API hatası durumunda engelleme olmasın)
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
            // Yorumu kaydet
            try commentRef.setData(from: comment) { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                // Yorum sayısını artır
                postRef.updateData(["comments": FieldValue.increment(Int64(1))]) { error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    // Etkileşimi kaydet ve duygu analizi yap
                    Task {
                        do {
                            // Yorum için API çağrısı yapmayalım
                            let emotionAnalysis = try await self.emotionService.analyzeEmotion(text: comment.content, operationType: .other)
                            try await self.userEmotionService.saveInteraction(
                                userId: userId,
                                postId: postId,
                                interactionType: .comment,
                                emotion: emotionAnalysis.emotion,
                                confidence: emotionAnalysis.confidence
                            )
                            // İşlem başarıyla tamamlandı
                            await MainActor.run {
                                completion(nil)
                            }
                        } catch {
                            print("Yorum etkileşimi kaydedilemedi: \(error)")
                            // Hata olsa bile yorum eklenmiş olmalı
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
                print("Yorumlar dinlenirken hata oluştu: \(error?.localizedDescription ?? "Bilinmeyen hata")")
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
                // Görüntüleme için API çağrısı yapmayalım
                let emotionAnalysis = try await emotionService.analyzeEmotion(text: post.content, operationType: .other)
                try await userEmotionService.saveInteraction(
                    userId: userId,
                    postId: postId,
                    interactionType: .viewDetail,
                    emotion: emotionAnalysis.emotion,
                    confidence: emotionAnalysis.confidence
                )
            } catch {
                print("Görüntüleme etkileşimi kaydedilemedi: \(error)")
            }
        }
    }
} 
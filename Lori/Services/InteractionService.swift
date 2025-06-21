import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Kullanıcı etkileşimlerini yöneten servis
/// Bu servis beğeni, yorum, görüntüleme gibi etkileşimleri işler
/// Ayrıca duygu analizi ve bildirim gönderme işlemlerini de yapar
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
    /// Bu fonksiyon toggle mantığıyla çalışır - eğer beğenilmişse kaldırır, beğenilmemişse ekler
    /// Beğeni işlemi sırasında post'un duygusunu API ile analiz eder ve kullanıcı etkileşimini kaydeder
    /// Ayrıca beğeni bildirimi gönderir (kendi postunu beğenmediği sürece)
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
                    
                    // Beğeni kaldırma etkileşimini kaydet
                    Task {
                        do {
                            // Post'un duygusunu API ile analiz et
                            let emotion: String
                            let confidence: Double
                            
                            if !post.content.isEmpty {
                                // Post içeriğini API ile analiz et
                                let emotionAnalysis = try await self.emotionService.analyzeEmotion(text: post.content, operationType: .like)
                                emotion = emotionAnalysis.emotion
                                confidence = emotionAnalysis.confidence
                                print("🔍 Post emotion analysis for dislike: \(emotion) (confidence: \(confidence))")
                            } else {
                                // Post içeriği yoksa varsayılan duygu kullan
                                emotion = "Neşe (Joy)"
                                confidence = 0.5
                                print("🔍 No post content for emotion analysis, using default: \(emotion)")
                            }
                            
                            try await self.userEmotionService.saveInteraction(
                                userId: userId,
                                postId: postId,
                                interactionType: .dislike,
                                emotion: emotion,
                                confidence: confidence
                            )
                            // İşlem başarıyla tamamlandı
                            await MainActor.run {
                                completion(!isLiked, nil)
                            }
                        } catch {
                            print("Dislike interaction could not be saved: \(error)")
                            // Hata olsa bile beğeni kaldırma işlemi tamamlanmalı
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
                    
                    // Etkileşimi kaydet ve bildirim gönder
                    Task {
                        do {
                            // Post'un duygusunu API ile analiz et
                            let emotion: String
                            let confidence: Double
                            
                            if !post.content.isEmpty {
                                // Post içeriğini API ile analiz et
                                let emotionAnalysis = try await self.emotionService.analyzeEmotion(text: post.content, operationType: .like)
                                emotion = emotionAnalysis.emotion
                                confidence = emotionAnalysis.confidence
                                print("🔍 Post emotion analysis for like: \(emotion) (confidence: \(confidence))")
                            } else {
                                // Post içeriği yoksa varsayılan duygu kullan
                                emotion = "Neşe (Joy)"
                                confidence = 0.5
                                print("🔍 No post content for emotion analysis, using default: \(emotion)")
                            }
                            
                            try await self.userEmotionService.saveInteraction(
                                userId: userId,
                                postId: postId,
                                interactionType: .like,
                                emotion: emotion,
                                confidence: confidence
                            )
                            
                            // İşlem başarıyla tamamlandı
                            await MainActor.run {
                                completion(!isLiked, nil)
                            }
                        } catch {
                            print("Like interaction could not be saved: \(error)")
                            // Hata olsa bile beğeni işlemi tamamlanmalı
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
    /// Bu fonksiyon gerçek zamanlı güncellemeler sağlar
    /// Firestore listener kullanarak beğeni değişikliklerini anında yakalar
    /// - Parameters:
    ///   - postId: Post ID
    ///   - onUpdate: Güncelleme olduğunda çağrılacak closure (beğeni sayısı, kullanıcının beğeni durumu)
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
    /// Bu fonksiyon önce nefret söylemi kontrolü yapar
    /// Eğer nefret söylemi tespit edilirse yorumu eklemez
    /// Yorum eklendikten sonra duygu analizi yapar ve bildirim gönderir
    /// - Parameters:
    ///   - comment: Eklenecek yorum
    ///   - post: Yorumun ekleneceği post
    ///   - completion: İşlem tamamlandığında çağrılacak closure (Error?: hata mesajı)
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
                // ÖNEMLİ: API'nin isHateSpeech değerine güvenme, her zaman kategori "1" kontrolü yap
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
                // API hatası durumunda bile yorumu ekle (API hatası nedeniyle engelleme)
                await saveComment(comment: comment, postId: postId, userId: userId, completion: completion)
            }
        }
    }
    
    /// Yorumu kaydeder ve etkileşimi kaydeder
    /// Bu fonksiyon yorumu Firestore'a kaydeder, yorum sayısını artırır
    /// Duygu analizi yapar ve bildirim gönderir
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
                            // Yorum için API çağrısı yap
                            let emotionAnalysis = try await self.emotionService.analyzeEmotion(text: comment.content, operationType: .comment)
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
                            print("Comment interaction could not be saved: \(error)")
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
    /// Bu fonksiyon gerçek zamanlı yorum güncellemeleri sağlar
    /// Yorumlar tarih sırasına göre sıralanır (en yeni önce)
    /// - Parameters:
    ///   - postId: Post ID
    ///   - onUpdate: Güncelleme olduğunda çağrılacak closure (yorum listesi)
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
    
    /// Post görüntüleme sayısını artırır (ana feed için)
    /// Bu fonksiyon sadece görüntüleme sayısını artırır, duygu analizi yapmaz
    /// Ana feed'de post görüntülendiğinde kullanılır
    /// - Parameters:
    ///   - post: Görüntülenen post
    func recordViewInteraction(for post: Post) {
        guard let postId = post.id,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        // Post'un views alt koleksiyonunda kullanıcının görüntüleme kaydını kontrol et
        let viewRef = db.collection("posts")
            .document(postId)
            .collection("views")
            .document(userId)
        
        // Önce kullanıcının daha önce görüntüleyip görüntülemediğini kontrol et
        viewRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Görüntüleme kontrolü sırasında hata: \(error.localizedDescription)")
                return
            }
            
            // Eğer kullanıcı daha önce görüntülemediyse
            if snapshot?.exists == false {
                // Görüntüleme kaydını oluştur
                viewRef.setData([
                    "timestamp": FieldValue.serverTimestamp(),
                    "userId": userId
                ]) { error in
                    if let error = error {
                        print("Görüntüleme kaydı oluşturulurken hata: \(error.localizedDescription)")
                        return
                    }
                    
                    // Post'un toplam görüntülenme sayısını artır
                    self.db.collection("posts").document(postId).updateData([
                        "viewCount": FieldValue.increment(Int64(1))
                    ]) { error in
                        if let error = error {
                            print("Görüntülenme sayısı güncellenirken hata: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    /// Post detay görüntüleme etkileşimini kaydeder (post detail sayfası için)
    /// Bu fonksiyon post detayına bakıldığında hem görüntüleme sayısını artırır hem de duygu analizi yapar
    /// Sadece post detail sayfasında kullanılır
    /// - Parameters:
    ///   - post: Detayı görüntülenen post
    func recordDetailViewInteraction(for post: Post) {
        guard let postId = post.id,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        // Post'un views alt koleksiyonunda kullanıcının görüntüleme kaydını kontrol et
        let viewRef = db.collection("posts")
            .document(postId)
            .collection("views")
            .document(userId)
        
        // Önce kullanıcının daha önce görüntüleyip görüntülemediğini kontrol et
        viewRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Görüntüleme kontrolü sırasında hata: \(error.localizedDescription)")
                return
            }
            
            // Eğer kullanıcı daha önce görüntülemediyse
            if snapshot?.exists == false {
                // Görüntüleme kaydını oluştur
                viewRef.setData([
                    "timestamp": FieldValue.serverTimestamp(),
                    "userId": userId
                ]) { error in
                    if let error = error {
                        print("Görüntüleme kaydı oluşturulurken hata: \(error.localizedDescription)")
                        return
                    }
                    
                    // Post'un toplam görüntülenme sayısını artır
                    self.db.collection("posts").document(postId).updateData([
                        "viewCount": FieldValue.increment(Int64(1))
                    ]) { error in
                        if let error = error {
                            print("Görüntülenme sayısı güncellenirken hata: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            // Post detayına bakıldığında duygu analizi yap ve etkileşimi kaydet (her zaman)
            Task {
                do {
                    let emotion: String
                    let confidence: Double
                    
                    if !post.content.isEmpty {
                        // Post içeriğini API ile analiz et
                        let emotionAnalysis = try await self.emotionService.analyzeEmotion(text: post.content, operationType: .like)
                        emotion = emotionAnalysis.emotion
                        confidence = emotionAnalysis.confidence
                        print("🔍 Post emotion analysis for detail view: \(emotion) (confidence: \(confidence))")
                    } else {
                        // Post içeriği yoksa varsayılan duygu kullan
                        emotion = "joy"
                        confidence = 0.5
                        print("🔍 No post content for emotion analysis, using default: \(emotion)")
                    }
                    
                    try await self.userEmotionService.saveInteraction(
                        userId: userId,
                        postId: postId,
                        interactionType: .viewDetail,
                        emotion: emotion,
                        confidence: confidence
                    )
                    print("✅ Detail view interaction saved with emotion: \(emotion)")
                } catch {
                    print("Detail view interaction could not be saved: \(error)")
                }
            }
        }
    }
} 

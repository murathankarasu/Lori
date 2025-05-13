import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AddCommentViewModel: ObservableObject {
    @Published var commentText: String = ""
    @Published var isPosting = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showHateSpeechWarning = false
    @Published var isCheckingHateSpeech = false
    @Published var isHateSpeechDetected = false
    @Published var isLoading = false
    
    let maxContentLength = 500
    
    private let emotionService = EmotionService.shared
    private let userEmotionService = UserEmotionService.shared
    
    var canPost: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isPosting &&
        !isCheckingHateSpeech
    }
    
    func checkHateSpeech(text: String) async throws -> (Bool, String, Double) {
        let trimmedContent = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return (false, "", 0.0) }
        let localCheck = HateSpeechService.shared.checkLocalHateSpeech(trimmedContent)
        if localCheck.containsHateSpeech {
            return (true, localCheck.category ?? "Nefret Söylemi", 1.0)
        }
        do {
            let response = try await HateSpeechService.shared.checkHateSpeech(text: trimmedContent)
            let isHateSpeech = response.data.category == "1"
            let category = isHateSpeech ? "Nefret Söylemi" : "Güvenli"
            return (isHateSpeech, category, response.data.confidence)
        } catch {
            print("Nefret söylemi kontrolü hatası: \(error)")
            return (false, "Güvenli", 0.0)
        }
    }
    
    func addComment(to post: Post, completion: @escaping (Bool) -> Void) async {
        guard canPost else { return }
        isPosting = true
        defer { isPosting = false }
        do {
            guard let user = Auth.auth().currentUser else {
                throw NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Oturum açmanız gerekiyor"])
            }
            guard let postId = post.id else {
                throw NSError(domain: "post", code: 400, userInfo: [NSLocalizedDescriptionKey: "Gönderi bulunamadı"])
            }
            let trimmedContent = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedContent.isEmpty else {
                throw NSError(domain: "content", code: 400, userInfo: [NSLocalizedDescriptionKey: "Yorum boş olamaz"])
            }
            // Nefret söylemi kontrolü
            let (isHateSpeech, category, _) = try await checkHateSpeech(text: trimmedContent)
            if isHateSpeech {
                showHateSpeechWarning = true
                errorMessage = "Nefret söylemi tespit edildi. Kategori: \(category)"
                showError = true
                completion(false)
                return
            }
            // Duygu analizi
            let emotionAnalysis = try await emotionService.analyzeEmotion(text: trimmedContent)
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let username = userDoc.data()? ["username"] as? String ?? user.displayName ?? "Anonim"
            // Yorum modelini oluştur
            let comment = Comment(
                id: UUID().uuidString,
                postId: postId,
                userId: user.uid,
                username: username,
                content: trimmedContent,
                timestamp: Date()
            )
            // Firestore'a kaydet
            let commentId = comment.id ?? UUID().uuidString
            let commentData: [String: Any] = [
                "postId": comment.postId,
                "userId": comment.userId,
                "username": username,
                "content": comment.content,
                "timestamp": Timestamp(date: comment.timestamp),
                "emotionAnalysis": [
                    "emotion": emotionAnalysis.emotion,
                    "confidence": emotionAnalysis.confidence,
                    "timestamp": Timestamp(date: emotionAnalysis.timestamp)
                ]
            ]
            try await db.collection("posts").document(postId).collection("comments").document(commentId).setData(commentData)
            // commentsCount alanını artır
            try await db.collection("posts").document(postId).updateData([
                "commentsCount": FieldValue.increment(Int64(1))
            ])
            // Etkileşimi kaydet
            try await userEmotionService.saveInteraction(
                userId: user.uid,
                postId: postId,
                interactionType: .comment,
                emotion: emotionAnalysis.emotion,
                confidence: emotionAnalysis.confidence
            )
            completion(true)
        } catch {
            print("Yorum eklenirken hata: \(error)")
            errorMessage = error.localizedDescription
            showError = true
            completion(false)
        }
    }
    
    func clearComment() {
        commentText = ""
        showHateSpeechWarning = false
        isPosting = false
        isCheckingHateSpeech = false
    }
} 

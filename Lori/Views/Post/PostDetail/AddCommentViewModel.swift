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
    private let interactionService = InteractionService.shared
    private let hateSpeechService = HateSpeechService.shared
    
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
            let response = try await hateSpeechService.checkHateSpeech(text: trimmedContent)
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
                throw NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "You need to sign in"])
            }
            guard let postId = post.id else {
                throw NSError(domain: "post", code: 400, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
            }
            
            let trimmedContent = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedContent.isEmpty else {
                throw NSError(domain: "content", code: 400, userInfo: [NSLocalizedDescriptionKey: "Comment cannot be empty"])
            }
            
            // Hate speech check
            let (isHateSpeech, category, _) = try await checkHateSpeech(text: trimmedContent)
            if isHateSpeech {
                showHateSpeechWarning = true
                errorMessage = "Hate speech detected. Category: \(category)"
                showError = true
                completion(false)
                return
            }
            
            // Get username from Firestore
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? user.displayName ?? "Anonymous"
            
            // Create comment model
            let comment = Comment(
                id: UUID().uuidString,
                postId: postId,
                userId: user.uid,
                username: username,
                content: trimmedContent,
                timestamp: Date()
            )
            
            // InteractionService kullanarak yorumu ekle
            interactionService.addComment(comment: comment, to: post) { error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    completion(false)
                } else {
                    completion(true)
                }
            }
            
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

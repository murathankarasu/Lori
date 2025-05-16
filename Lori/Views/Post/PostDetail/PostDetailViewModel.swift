import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var post: Post?
    @Published var comments: [Comment] = []
    @Published var isLiked: Bool = false
    @Published var likesCount: Int = 0
    @Published var disinformationCheck: DisinformationResponse?
    @Published var isCheckingDisinformation = false
    @Published var commentsCount: Int = 0
    
    // Dezenformasyon kontrolünün gösterilip gösterilmeyeceğini belirleyen özellik
    var shouldShowDisinformationCheck: Bool {
        guard let post = post else { return false }
        
        // Anahtar kelimeleri kontrol et
        let newsKeywords = [
            // General News & Information
            "news", "announcement", "statement", "declaration", "announced", "said", "claimed",
            "report", "research", "study", "result", "finding", "discovery", "development", "event",
            "latest", "breaking", "urgent", "important", "critical", "attention", "warning",
            
            // Science & Technology
            "science", "technology", "research", "study", "experiment", "discovery", "invention",
            "scientist", "researcher", "laboratory", "data", "analysis", "theory", "hypothesis",
            "quantum", "genetic", "molecular", "atomic", "particle", "evolution", "climate",
            
            // Health & Medicine
            "health", "medical", "disease", "virus", "bacteria", "vaccine", "treatment",
            "doctor", "hospital", "patient", "symptom", "diagnosis", "prescription", "medicine",
            "pandemic", "epidemic", "infection", "immune", "vaccination", "clinical", "trial",
            
            // Politics & Government
            "government", "president", "minister", "parliament", "election", "vote", "law",
            "policy", "regulation", "decision", "announcement", "statement", "official",
            "administration", "ministry", "department", "agency", "commission", "committee",
            
            // Economy & Business
            "economy", "business", "market", "stock", "investment", "company", "industry",
            "financial", "economic", "trade", "commerce", "bank", "currency", "inflation",
            "recession", "growth", "development", "enterprise", "corporation", "organization",
            
            // Environment & Nature
            "environment", "climate", "nature", "earth", "planet", "global", "warming",
            "pollution", "conservation", "sustainability", "ecosystem", "biodiversity",
            "wildlife", "forest", "ocean", "atmosphere", "weather", "disaster", "natural",
            
            // Education & Academia
            "education", "university", "school", "student", "teacher", "professor", "academic",
            "research", "study", "learning", "teaching", "knowledge", "science", "discipline",
            "degree", "course", "program", "institution", "faculty", "department"
        ]
        
        let lowercasedContent = post.content.lowercased()
        return newsKeywords.contains { lowercasedContent.contains($0) }
    }
    
    private let db = Firestore.firestore()
    private var commentsListener: ListenerRegistration?
    private var likesListener: ListenerRegistration?
    private let disinformationService = DisinformationService()
    private let interactionService = InteractionService.shared
    
    func loadPostDetails(_ post: Post) {
        // Unwrap post.id early
        guard let postId = post.id else {
            print("❌ Post ID is nil in loadPostDetails.")
            return
        }
        self.post = post
        setupListeners(post)
        fetchComments(for: postId)
        checkIfLiked(postId: postId)
        fetchLikesCount(postId: postId)
        listenCommentsCount(postId: postId)
        
        // Post görüntüleme etkileşimini kaydet
        interactionService.recordViewInteraction(for: post)
        
        // Sadece gerekli durumlarda dezenformasyon kontrolü yap
        if shouldShowDisinformationCheck {
            checkInitialDisinformation(for: post)
        }
    }
    
    private func setupListeners(_ post: Post) {
        // Unwrap post.id
        guard let postId = post.id else {
            print("❌ Post ID is nil in setupListeners.")
            return
        }
        
        // Önceki dinleyicileri temizle
        commentsListener?.remove()
        likesListener?.remove()
        
        // Yorumları dinle
        commentsListener = interactionService.listenToComments(for: postId) { [weak self] comments in
            self?.comments = comments
        }
        
        // Beğenileri dinle
        likesListener = interactionService.listenToLikes(for: postId) { [weak self] count, isLiked in
            self?.likesCount = count
            self?.isLiked = isLiked
        }
    }
    
    func toggleLike() {
        guard let post = post else { return }
        
        interactionService.toggleLike(for: post, isLiked: isLiked) { [weak self] newIsLiked, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Beğeni işlemi sırasında hata: \(error.localizedDescription)")
                return
            }
            
            // UI güncellemesi MainActor'da yapılacak
            Task { @MainActor in
                self.isLiked = newIsLiked
            }
        }
    }
    
    func deletePost(_ post: Post, completion: @escaping () -> Void) {
        // Unwrap post.id
        guard let postId = post.id else {
             print("❌ Post ID is nil in deletePost.")
             // Optionally call completion with an error or just return
             return
         }
        db.collection("posts")
            .document(postId)
            .delete { error in
                if let error = error {
                    print("Gönderi silinirken hata oluştu: \(error.localizedDescription)")
                } else {
                    completion()
                }
            }
    }
    
    func loadComments() {
        guard let post = post else { return }
        setupListeners(post)
    }
    
    func checkDisinformation(for postToCheck: Post) {
        // Sadece gerekli durumlarda dezenformasyon kontrolü yap
        guard shouldShowDisinformationCheck else {
            self.disinformationCheck = nil
            return
        }
        
        isCheckingDisinformation = true
        Task {
            do {
                let checkResult = try await disinformationService.checkDisinformation(for: postToCheck)
                self.disinformationCheck = checkResult
            } catch {
                print("Dezenformasyon kontrolü hatası (ViewModel): \(error)")
                self.disinformationCheck = nil
            }
            self.isCheckingDisinformation = false
        }
    }
    
    private func checkInitialDisinformation(for postToCheck: Post) {
        checkDisinformation(for: postToCheck)
    }
    
    func fetchComments(for postId: String) {
        commentsListener?.remove()
        commentsListener = interactionService.listenToComments(for: postId) { [weak self] comments in
            self?.comments = comments
        }
    }

    func checkIfLiked(postId: String) {
        // InteractionService ile beğeni durumunu dinliyoruz, bu metot artık gerekli değil
        // Ancak uyumluluk için boş bırakıyoruz
    }
    
    func fetchLikesCount(postId: String) {
        // InteractionService ile beğeni sayısını dinliyoruz, bu metot artık gerekli değil
        // Ancak uyumluluk için boş bırakıyoruz
    }
    
    private func listenCommentsCount(postId: String) {
        db.collection("posts").document(postId).addSnapshotListener { [weak self] snapshot, error in
            guard let data = snapshot?.data() else { return }
            self?.commentsCount = data["commentsCount"] as? Int ?? 0
        }
    }
    
    deinit {
        commentsListener?.remove()
        likesListener?.remove()
    }
} 
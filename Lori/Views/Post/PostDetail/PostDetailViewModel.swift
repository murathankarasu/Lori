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
        // Yorumları dinle
        commentsListener?.remove()
        commentsListener = db.collection("posts")
            .document(postId)
            .collection("comments")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Yorumlar yüklenirken hata oluştu: \(error?.localizedDescription ?? "")")
                    return
                }
                
                self?.comments = documents.compactMap { document -> Comment? in
                    try? document.data(as: Comment.self)
                }
            }
        
        // Beğenileri dinle
        likesListener?.remove()
        likesListener = db.collection("posts")
            .document(postId)
            .collection("likes")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Beğeniler yüklenirken hata oluştu: \(error?.localizedDescription ?? "")")
                    return
                }
                
                self?.likesCount = documents.count
                if let userId = Auth.auth().currentUser?.uid {
                    self?.isLiked = documents.contains { $0.documentID == userId }
                }
            }
    }
    
    func toggleLike() {
        guard let post = post,
              let postId = post.id,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let likeRef = db.collection("posts")
            .document(postId)
            .collection("likes")
            .document(userId)
        
        if isLiked {
            likeRef.delete()
        } else {
            likeRef.setData([:])
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
        db.collection("posts").document(postId).collection("comments")
          .order(by: "timestamp", descending: false)
          .addSnapshotListener { querySnapshot, error in
              guard let documents = querySnapshot?.documents else {
                  print("Error fetching comments: \(error?.localizedDescription ?? "Unknown error")")
                  return
              }
              self.comments = documents.compactMap { try? $0.data(as: Comment.self) }
          }
    }

    func checkIfLiked(postId: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userId).collection("likedPosts").document(postId)
            .getDocument { document, _ in
                self.isLiked = document?.exists ?? false
            }
    }
    
    func fetchLikesCount(postId: String) {
         db.collection("posts").document(postId)
             .addSnapshotListener { documentSnapshot, error in
                 guard let document = documentSnapshot else {
                     print("Error fetching likes count: \(error?.localizedDescription ?? "Unknown error")")
                     return
                 }
                 self.likesCount = document.data()?["likes"] as? Int ?? 0
             }
     }
    
    deinit {
        commentsListener?.remove()
        likesListener?.remove()
    }
} 
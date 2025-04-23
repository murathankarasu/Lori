import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class PostDetailViewModel: ObservableObject {
    @Published var post: Post?
    @Published var comments: [Comment] = []
    @Published var isLiked: Bool = false
    @Published var likesCount: Int = 0
    @Published var disinformationCheck: DisinformationResponse?
    @Published var isCheckingDisinformation = false
    
    private let db = Firestore.firestore()
    private var commentsListener: ListenerRegistration?
    private var likesListener: ListenerRegistration?
    private let disinformationService = DisinformationService()
    
    func loadPostDetails(_ post: Post) {
        self.post = post
        setupListeners(post)
        fetchComments(for: post.id)
        checkIfLiked(postId: post.id)
        fetchLikesCount(postId: post.id)
        checkInitialDisinformation(for: post)
    }
    
    private func setupListeners(_ post: Post) {
        // Yorumları dinle
        commentsListener?.remove()
        commentsListener = db.collection("posts")
            .document(post.id)
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
            .document(post.id)
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
              let userId = Auth.auth().currentUser?.uid else { return }
        
        let likeRef = db.collection("posts")
            .document(post.id)
            .collection("likes")
            .document(userId)
        
        if isLiked {
            likeRef.delete()
        } else {
            likeRef.setData([:])
        }
    }
    
    func deletePost(_ post: Post, completion: @escaping () -> Void) {
        db.collection("posts")
            .document(post.id)
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
    
    func verifyPostManually() {
        guard let currentPost = self.post else {
            print("Hata: Manuel doğrulama için gönderi yüklenemedi.")
            return
        }
        print("Manuel doğrulama başlatıldı: \(currentPost.id)")
        checkDisinformation(for: currentPost)
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
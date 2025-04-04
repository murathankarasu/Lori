import Foundation
import FirebaseFirestore
import FirebaseAuth

class PostDetailViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLiked: Bool = false
    @Published var likesCount: Int = 0
    
    private let db = Firestore.firestore()
    private var post: Post?
    private var commentsListener: ListenerRegistration?
    private var likesListener: ListenerRegistration?
    
    func loadPostDetails(_ post: Post) {
        self.post = post
        setupListeners(post)
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
    
    deinit {
        commentsListener?.remove()
        likesListener?.remove()
    }
} 
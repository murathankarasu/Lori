import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FollowingFeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() {
        fetchFollowingPosts()
    }

    deinit {
        listener?.remove()
    }

    func fetchFollowingPosts() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Kullanıcı girişi yapılmamış."
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        // 1. Get the list of users the current user is following
        db.collection("following").document(currentUserId).getDocument { [weak self] documentSnapshot, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = "Takip edilenler listesi alınamadı: \(error.localizedDescription)"
                self.isLoading = false
                print("Error fetching following list: \(error.localizedDescription)")
                return
            }

            guard let document = documentSnapshot, document.exists,
                  let followingIds = document.data()?["users"] as? [String], !followingIds.isEmpty else {
                // User is not following anyone
                self.posts = []
                self.isLoading = false
                print("User is not following anyone.")
                return
            }
            
            print("Fetching posts for followed users: \(followingIds)")

            // 2. Fetch posts from the followed users
            // Remove previous listener if exists
            self.listener?.remove()
            
            // Firestore limits 'in' queries to 30 items per query.
            // If the user follows more than 30 people, we need to split the query.
            // For simplicity here, we'll assume <= 30 for now. A production app would need pagination/splitting.
            // TODO: Handle more than 30 followed users.
            if followingIds.count > 30 {
                 print("Warning: User follows more than 30 people. Firestore 'in' query limit might be exceeded. Fetching only the first 30.")
                 // Consider splitting into multiple queries or implementing pagination
            }
            let limitedFollowingIds = Array(followingIds.prefix(30))


            self.listener = self.db.collection("posts")
                .whereField("userId", in: limitedFollowingIds) // Use limited list
                .order(by: "timestamp", descending: true)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        self.errorMessage = "Gönderiler yüklenirken hata oluştu: \(error.localizedDescription)"
                        self.isLoading = false
                        print("Error fetching posts: \(error.localizedDescription)")
                        return
                    }

                    guard let documents = querySnapshot?.documents else {
                        self.errorMessage = "Gönderiler yüklenemedi."
                        self.isLoading = false
                        print("No documents found in snapshot.")
                        return
                    }
                    
                    print("Fetched \(documents.count) posts from followed users.")

                    self.posts = documents.compactMap { document -> Post? in
                        try? document.data(as: Post.self)
                    }
                    self.isLoading = false
                    self.errorMessage = nil // Clear error on success
                }
        }
    }
} 
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [User] = []
    @Published var recentSearches: [User] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private var searchTask: Task<Void, Never>?
    
    init() {
        loadRecentSearches()
    }
    
    private func loadRecentSearches() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(currentUserId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Son aramalar yüklenemedi: \(error.localizedDescription)")
                return
            }
            
            let recentSearchIds = snapshot?.data()?["recentSearches"] as? [String] ?? []
            
            // Son aramaları yükle
            Task {
                await self.fetchUsers(by: recentSearchIds)
            }
        }
    }
    
    private func fetchUsers(by ids: [String]) async {
        do {
            var users: [User] = []
            
            for id in ids {
                let doc = try await db.collection("users").document(id).getDocument()
                if let data = doc.data() {
                    let user = User(
                        id: doc.documentID,
                        username: data["username"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        profileImageUrl: data["profileImageUrl"] as? String,
                        bio: data["bio"] as? String,
                        followers: data["followers"] as? Int ?? 0,
                        following: data["following"] as? Int ?? 0,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        isVerified: data["isVerified"] as? Bool ?? false
                    )
                    users.append(user)
                }
            }
            
            self.recentSearches = users
        } catch {
            print("Kullanıcılar yüklenemedi: \(error.localizedDescription)")
        }
    }
    
    func searchUsers() {
        searchTask?.cancel()
        
        searchTask = Task {
            do {
                guard !searchText.isEmpty else {
                    searchResults = []
                    return
                }
                
                isLoading = true
                
                let querySnapshot = try await db.collection("users")
                    .whereField("username", isGreaterThanOrEqualTo: searchText)
                    .whereField("username", isLessThanOrEqualTo: searchText + "\u{f8ff}")
                    .limit(to: 20)
                    .getDocuments()
                
                let users = querySnapshot.documents.compactMap { document -> User? in
                    let data = document.data()
                    return User(
                        id: document.documentID,
                        username: data["username"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        profileImageUrl: data["profileImageUrl"] as? String,
                        bio: data["bio"] as? String,
                        followers: data["followers"] as? Int ?? 0,
                        following: data["following"] as? Int ?? 0,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        isVerified: data["isVerified"] as? Bool ?? false
                    )
                }
                
                if !Task.isCancelled {
                    searchResults = users
                    isLoading = false
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
    
    func addRecentSearch(_ user: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Eğer kullanıcı zaten son aramalarda varsa, onu kaldır
        recentSearches.removeAll { $0.id == user.id }
        
        // Kullanıcıyı en başa ekle
        recentSearches.insert(user, at: 0)
        
        // En fazla 10 son arama tut
        if recentSearches.count > 10 {
            recentSearches.removeLast()
        }
        
        // Firestore'a kaydet
        let recentSearchIds = recentSearches.map { $0.id }
        db.collection("users").document(currentUserId).updateData([
            "recentSearches": recentSearchIds
        ])
    }
    
    func removeRecentSearch(_ user: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        recentSearches.removeAll { $0.id == user.id }
        
        let recentSearchIds = recentSearches.map { $0.id }
        db.collection("users").document(currentUserId).updateData([
            "recentSearches": recentSearchIds
        ])
    }
} 
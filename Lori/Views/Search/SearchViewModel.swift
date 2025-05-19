import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [User] = []
    @Published var recentSearches: [User] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadRecentSearches()
        setupSearchPublisher()
    }
    
    private func setupSearchPublisher() {
        // Debounce ekleyerek, kullanıcı yazıyı bitirdikten 0.5 saniye sonra aramayı başlat
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] text in
                if !text.isEmpty {
                    self?.searchUsers()
                } else {
                    self?.searchResults = []
                }
            }
            .store(in: &cancellables)
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
        guard !ids.isEmpty else {
            self.recentSearches = []
            return
        }
        
        do {
            var users: [User] = []
            
            // Chunks içinde işleyelim (Firestore 'in' sorgularında 10'dan fazla ID kullanmak sorun çıkarabilir)
            let chunks = stride(from: 0, to: ids.count, by: 10).map {
                Array(ids[$0..<min($0 + 10, ids.count)])
            }
            
            for chunk in chunks {
                let querySnapshot = try await db.collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                
                for document in querySnapshot.documents {
                    let data = document.data()
                    let user = User(
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
                    users.append(user)
                }
            }
            
            // ID'lerin sırasına göre sonuçları sırala (en son aranan en başta)
            self.recentSearches = ids.compactMap { id in
                users.first { $0.id == id }
            }
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
                
                // Küçük/büyük harf duyarlılığını kaldırmak için yazıyı küçük harfe çevirelim
                let lowercaseSearch = searchText.lowercased()
                
                // Önce tam eşleşenleri, sonra içerenleri bulalım
                let querySnapshot = try await db.collection("users")
                    .whereField("usernameLower", isGreaterThanOrEqualTo: lowercaseSearch)
                    .whereField("usernameLower", isLessThanOrEqualTo: lowercaseSearch + "\u{f8ff}")
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
                    
                    // Aramayı analitik için kaydet
                    if !searchText.isEmpty {
                        saveSearchAnalytics(term: searchText)
                    }
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
    
    // Bu fonksiyon arama terimlerini analitik için kaydeder
    private func saveSearchAnalytics(term: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let searchData: [String: Any] = [
            "term": term,
            "userId": currentUserId,
            "timestamp": Timestamp(),
            "resultCount": searchResults.count
        ]
        
        // searchAnalytics koleksiyonuna ekle
        db.collection("searchAnalytics").addDocument(data: searchData) { error in
            if let error = error {
                print("Arama analitiği kaydedilemedi: \(error.localizedDescription)")
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
    
    // Bir kullanıcının profiline tıklandığında çağrılır
    func userProfileTapped(_ user: User) {
        // Son aramalara ekle
        addRecentSearch(user)
        
        // Arama analitiğine tıklama eventi ekle
        logProfileClick(userId: user.id)
    }
    
    // Profil tıklamalarını analitikler için kaydet
    private func logProfileClick(userId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let clickData: [String: Any] = [
            "type": "profile_click",
            "sourceUserId": currentUserId,
            "targetUserId": userId,
            "timestamp": Timestamp(),
            "searchTerm": searchText
        ]
        
        db.collection("userInteractions").addDocument(data: clickData) { error in
            if let error = error {
                print("Profil tıklama analitiği kaydedilemedi: \(error.localizedDescription)")
            }
        }
    }
} 
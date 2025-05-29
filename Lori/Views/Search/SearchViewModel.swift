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
                print("[SearchViewModel] Arama barına input girildi: \(text)")
                if !text.isEmpty {
                    print("[SearchViewModel] Debounce sonrası arama başlatılıyor: \(text)")
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
        print("[SearchViewModel] Firestore'dan kullanıcılar fetch ediliyor: \(ids)")
        guard !ids.isEmpty else {
            await MainActor.run { self.recentSearches = [] }
            print("[SearchViewModel] Fetch edilen kullanıcı yok (boş id listesi)")
            return
        }
        do {
            var users: [User] = []
            let chunks = stride(from: 0, to: ids.count, by: 10).map {
                Array(ids[$0..<min($0 + 10, ids.count)])
            }
            for chunk in chunks {
                print("[SearchViewModel] Firestore sorgusu başlatıldı (chunk): \(chunk)")
                let querySnapshot = try await db.collection("users")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                print("[SearchViewModel] Firestore sorgusu tamamlandı (chunk): \(chunk), dönen: \(querySnapshot.documents.count) kullanıcı")
                for document in querySnapshot.documents {
                    let data = document.data()
                    let usernameLower = data["usernameLower"] as? String ?? (data["username"] as? String ?? "").lowercased()
                    let user = User(
                        id: document.documentID,
                        username: data["username"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        profileImageUrl: data["profileImageUrl"] as? String,
                        bio: data["bio"] as? String,
                        followers: data["followers"] as? Int ?? 0,
                        following: data["following"] as? Int ?? 0,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        isVerified: data["isVerified"] as? Bool ?? false,
                        usernameLower: usernameLower
                    )
                    guard user.isValid else {
                        print("[SearchViewModel] Geçersiz kullanıcı verisi atlandı - UserID: \(user.id), Username: \(user.username)")
                        continue
                    }
                    users.append(user)
                }
            }
            await MainActor.run {
                self.recentSearches = ids.compactMap { id in
                    users.first { $0.id == id }
                }
            }
            print("[SearchViewModel] Firestore'dan fetch edilen kullanıcı sayısı: \(users.count)")
        } catch {
            print("[SearchViewModel] Kullanıcılar yüklenemedi: \(error.localizedDescription)")
        }
    }
    
    func searchUsers() {
        print("[SearchViewModel] Kullanıcı arama başlatıldı: \(searchText)")
        searchTask?.cancel()
        searchTask = Task {
            do {
                guard !searchText.isEmpty else {
                    await MainActor.run { self.searchResults = [] }
                    print("[SearchViewModel] Arama metni boş, sonuç yok.")
                    return
                }
                await MainActor.run { self.isLoading = true }
                let lowercaseSearch = searchText.lowercased()
                var allUsers: [User] = []
                print("[SearchViewModel] Firestore'da userId ile arama başlatılıyor: \(searchText)")
                if let userByIdSnapshot = try? await db.collection("users").document(searchText).getDocument(),
                   userByIdSnapshot.exists {
                    let data = userByIdSnapshot.data() ?? [:]
                    let usernameLower = data["usernameLower"] as? String ?? (data["username"] as? String ?? "").lowercased()
                    let userById = User(
                        id: userByIdSnapshot.documentID,
                        username: data["username"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        profileImageUrl: data["profileImageUrl"] as? String,
                        bio: data["bio"] as? String,
                        followers: data["followers"] as? Int ?? 0,
                        following: data["following"] as? Int ?? 0,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        isVerified: data["isVerified"] as? Bool ?? false,
                        usernameLower: usernameLower
                    )
                    if userById.isValid {
                        allUsers.append(userById)
                        print("[SearchViewModel] Firestore userId ile eşleşen kullanıcı bulundu: \(userById.username)")
                    }
                }
                print("[SearchViewModel] Firestore'da usernameLower ile arama başlatılıyor: \(lowercaseSearch)")
                let usernameQuery = try await db.collection("users")
                    .whereField("usernameLower", isGreaterThanOrEqualTo: lowercaseSearch)
                    .whereField("usernameLower", isLessThanOrEqualTo: lowercaseSearch + "\u{f8ff}")
                    .limit(to: 15)
                    .getDocuments()
                print("[SearchViewModel] Firestore usernameLower arama sonucu: \(usernameQuery.documents.count) kullanıcı")
                let usernameUsers = usernameQuery.documents.compactMap { document -> User? in
                    let data = document.data()
                    let usernameLower = data["usernameLower"] as? String ?? (data["username"] as? String ?? "").lowercased()
                    let user = User(
                        id: document.documentID,
                        username: data["username"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        profileImageUrl: data["profileImageUrl"] as? String,
                        bio: data["bio"] as? String,
                        followers: data["followers"] as? Int ?? 0,
                        following: data["following"] as? Int ?? 0,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        isVerified: data["isVerified"] as? Bool ?? false,
                        usernameLower: usernameLower
                    )
                    return user.isValid ? user : nil
                }
                print("[SearchViewModel] Firestore'da email ile arama başlatılıyor: \(lowercaseSearch)")
                let emailQuery = try await db.collection("users")
                    .whereField("email", isGreaterThanOrEqualTo: lowercaseSearch)
                    .whereField("email", isLessThanOrEqualTo: lowercaseSearch + "\u{f8ff}")
                    .limit(to: 10)
                    .getDocuments()
                print("[SearchViewModel] Firestore email arama sonucu: \(emailQuery.documents.count) kullanıcı")
                let emailUsers = emailQuery.documents.compactMap { document -> User? in
                    let data = document.data()
                    let usernameLower = data["usernameLower"] as? String ?? (data["username"] as? String ?? "").lowercased()
                    let user = User(
                        id: document.documentID,
                        username: data["username"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        profileImageUrl: data["profileImageUrl"] as? String,
                        bio: data["bio"] as? String,
                        followers: data["followers"] as? Int ?? 0,
                        following: data["following"] as? Int ?? 0,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        isVerified: data["isVerified"] as? Bool ?? false,
                        usernameLower: usernameLower
                    )
                    return user.isValid ? user : nil
                }
                allUsers.append(contentsOf: usernameUsers)
                allUsers.append(contentsOf: emailUsers)
                var uniqueUsers: [User] = []
                var seenIds: Set<String> = []
                for user in allUsers {
                    if !seenIds.contains(user.id) {
                        uniqueUsers.append(user)
                        seenIds.insert(user.id)
                    }
                }
                uniqueUsers.sort { user1, user2 in
                    let search = lowercaseSearch
                    let username1 = user1.username.lowercased()
                    let username2 = user2.username.lowercased()
                    if username1 == search && username2 != search { return true }
                    if username2 == search && username1 != search { return false }
                    if username1.hasPrefix(search) && !username2.hasPrefix(search) { return true }
                    if username2.hasPrefix(search) && !username1.hasPrefix(search) { return false }
                    return user1.followers > user2.followers
                }
                if !Task.isCancelled {
                    await MainActor.run {
                        self.searchResults = Array(uniqueUsers.prefix(20))
                        self.isLoading = false
                    }
                    print("[SearchViewModel] Arama tamamlandı, sonuç sayısı: \(searchResults.count)")
                    if !searchText.isEmpty {
                        saveSearchAnalytics(term: searchText)
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.error = error
                        self.isLoading = false
                    }
                    print("[SearchViewModel] Arama sırasında hata oluştu: \(error.localizedDescription)")
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
    
    // Navigation için kullanılacak
    @Published var selectedUserId: String?
    @Published var shouldNavigateToProfile = false
    
    func navigateToProfile(_ user: User) {
        selectedUserId = user.id
        shouldNavigateToProfile = true
        userProfileTapped(user)
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
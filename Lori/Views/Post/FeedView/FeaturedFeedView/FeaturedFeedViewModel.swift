import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor // UI güncellemeleri ana thread'de yapılmalı
class FeaturedFeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = true
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let recommendationService = RecommendationService()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>() // Combine için
    
    // Listener'lar kaldırıldı
    // private var postsListener: ListenerRegistration?
    // private var userListener: ListenerRegistration?
    
    // deinit içinde listener temizleme kaldırıldı
    // deinit {
    //     postsListener?.remove()
    //     userListener?.remove()
    // }
    
    func loadPosts() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Kullanıcı girişi bulunamadı."
            showError = true
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = "" // Hata mesajını temizle
        showError = false
        
        Task {
            let result = await recommendationService.fetchRecommendations(userId: userId)
            
            switch result {
            case .success(let response):
                if response.success {
                    await processRecommendations(response.recommendations)
                } else {
                    handleError(message: "Öneriler alınamadı.")
                }
            case .failure(let error):
                handleError(message: "Öneri servisine ulaşılamadı: \(error.localizedDescription)")
            }
        }
    }
    
    private func processRecommendations(_ recommendedItems: [RecommendedItem]) async {
        var fetchedPosts: [String: Post] = [:]
        var adPosts: [Post] = []
        var postIdsToFetch: [String] = []
        
        // ID'leri ayıkla ve reklamları işle
        for item in recommendedItems {
            if item.isAdvertisement {
                // Reklamı doğrudan Post'a çevir
                adPosts.append(Post(from: item))
            } else {
                // Post ID'sini Firestore'dan çekmek üzere ekle
                postIdsToFetch.append(item.id)
            }
        }
        
        // Firestore'dan postları çek
        if !postIdsToFetch.isEmpty {
             do {
                 fetchedPosts = try await fetchPostsFromFirestore(ids: postIdsToFetch)
             } catch {
                 handleError(message: "Gönderiler Firestore'dan yüklenemedi: \(error.localizedDescription)")
                 // Hata olsa bile reklamları göstermeye devam edebiliriz
             }
        }
        
        // Öneri sırasına göre postları ve reklamları birleştir
        var combinedPosts: [Post] = []
        for item in recommendedItems {
            if item.isAdvertisement {
                // Önceden oluşturulmuş reklam postunu ekle
                 if let adPost = adPosts.first(where: { $0.id == item.id }) {
                     combinedPosts.append(adPost)
                 }
            } else {
                // Firestore'dan çekilen postu ekle
                if let post = fetchedPosts[item.id] {
                    combinedPosts.append(post)
                } else {
                    // Post Firestore'da bulunamadıysa logla veya atla
                    print("Uyarı: Önerilen post ID \(item.id) Firestore'da bulunamadı.")
                }
            }
        }
        
        // Yeni postları mevcut listenin başına ekle ve tekrarları kaldır
        // Set kullanarak ID bazında tekilleştirme
        let existingPostIDs = Set(self.posts.compactMap { $0.id })
        // Sadece mevcut listede olmayan yeni postları filtrele
        let uniqueNewPosts = combinedPosts.filter { !existingPostIDs.contains($0.id ?? "") }
        
        // Tekilleştirilmiş yeni postları mevcut listenin başına ekle
        self.posts.insert(contentsOf: uniqueNewPosts, at: 0)
        
        
        self.isLoading = false
    }
    
    private func fetchPostsFromFirestore(ids: [String]) async throws -> [String: Post] {
        guard !ids.isEmpty else { return [:] }
        
        // Firestore `in` sorgusu 10 elemanla sınırlı olabilir, büyük ID listelerini bölmek gerekebilir.
        // Firestore dokümanlarına göre 30 elemana kadar destekliyor (Aralık 2023 itibariyle)
        // Eğer 30'dan fazla ID varsa, istekleri bölerek yapmak daha güvenli olur.
        let chunks = ids.chunked(into: 30) // ID listesini 30'arlı gruplara böl
        var resultMap: [String: Post] = [:]

        for chunk in chunks {
            let snapshot = try await db.collection("posts")
                                     .whereField(FieldPath.documentID(), in: chunk)
                                     .getDocuments()
            
            for document in snapshot.documents {
                 // Post initializer'ı data: [String: Any] alacak şekilde güncellenmeli
                 // Veya burada manuel mapping yapılmalı
                if var post = Post(id: document.documentID, data: document.data()) {
                    // Eksik alanları (örn. comments, likes) ayrıca doldurmak gerekebilir
                    // Şimdilik sadece temel veriyi alıyoruz
                    resultMap[document.documentID] = post
                } else {
                    print("Error creating Post object from Firestore data for ID: \(document.documentID)")
                }
            }
        }
        return resultMap
    }
    
    private func handleError(message: String) {
        print("Error: \(message)")
        self.errorMessage = message
        self.showError = true
        self.isLoading = false
        // Hata durumunda boş post listesi göstermek veya eski listeyi korumak tercih edilebilir
        // self.posts = [] 
    }
    
    // Yeni fonksiyon: Gönderi detay görüntüleme etkileşimini kaydet
    func recordPostViewInteraction(post: Post) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error recording view interaction: User not logged in.")
            return
        }
        guard let postId = post.id else {
             print("Error recording view interaction: Post ID is missing.")
             return
        }
        
        // UserEmotionService'i kullanarak etkileşimi kaydet
        do {
            try await UserEmotionService.shared.saveInteraction(
                userId: userId,
                postId: postId,
                interactionType: .viewDetail,
                emotion: "viewing", // Veya "neutral"
                confidence: 0.0
            )
             print("View interaction recorded for post: \(postId)")
        } catch {
            print("Error saving view interaction for post \(postId): \(error.localizedDescription)")
            // Hata kullanıcıya gösterilmeyebilir, sadece loglanır.
        }
    }
    
    // Eski yükleme fonksiyonları kaldırıldı
    /*
    private func loadAllPosts() { ... }
    private func loadPostsByInterests(interests: [String]) { ... }
    private func handlePostsSnapshot(snapshot: QuerySnapshot?, error: Error?) { ... }
    */
}

// Array chunking extension (Helper)
/* // Bu extension başka bir yerde tanımlı olabilir, kaldırılıyor.
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
*/ 
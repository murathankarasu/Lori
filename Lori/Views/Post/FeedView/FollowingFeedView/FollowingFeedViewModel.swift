import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FollowingFeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false // Başlangıçta false, ilk fetch başlayınca true olur
    @Published var isFetchingMore = false // Sayfalama için yükleme durumu
    @Published var errorMessage: String?
    @Published var canLoadMore = true // Daha fazla gönderi olup olmadığını belirtir

    private let db = Firestore.firestore()
    private var lastDocumentSnapshot: DocumentSnapshot? // Son çekilen belgeyi tutar
    private let postsPerBatch = 20 // Her seferinde çekilecek gönderi sayısı

    init() {
        // init'te otomatik yükleme yok, onAppear tetikleyecek
    }

    deinit {
        // Listener olmadığı için temizlemeye gerek yok
        print("FollowingFeedViewModel deinit")
    }

    // İlk gönderi grubunu veya daha fazlasını çekmek için ana fonksiyon
    func fetchPosts(initial: Bool = false) {
        guard !isFetchingMore else { return } // Zaten yükleme yapılıyorsa tekrar başlatma
        
        if initial {
            print("FollowingFeedViewModel: Starting initial fetch...")
            isLoading = true
            lastDocumentSnapshot = nil // İlk yüklemede sıfırla
            canLoadMore = true // İlk yüklemede daha fazla olabileceğini varsay
            posts = [] // Listeyi temizle
        } else {
            guard canLoadMore, let _ = lastDocumentSnapshot else {
                print("FollowingFeedViewModel: Cannot load more, end reached or no snapshot.")
                return // Daha fazla yüklenemez veya son belge yok
            }
            print("FollowingFeedViewModel: Fetching more posts...")
            isFetchingMore = true
        }
        
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Kullanıcı girişi yapılmamış."
            if initial { isLoading = false } else { isFetchingMore = false }
            return
        }

        errorMessage = nil

        // 1. Kullanıcının takip ettiği kişilerin listesini al (`users` koleksiyonundan)
        db.collection("users").document(currentUserId).getDocument { [weak self] userSnapshot, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = "Kullanıcı bilgileri alınamadı: \(error.localizedDescription)"
                if initial { self.isLoading = false } else { self.isFetchingMore = false }
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }

            // Takip edilen kullanıcıların ID'leri
            let followingIds = userSnapshot?.data()?["following"] as? [String] ?? []
            
            // Takip edilenler ve kullanıcının kendisi için birleşik liste oluştur
            var allUserIds = followingIds
            
            // Kendi ID'sini her zaman listeye ekle
            if !allUserIds.contains(currentUserId) {
                allUserIds.append(currentUserId)
            }
            
            print("FollowingFeedViewModel: Total user IDs to fetch (including self): \(allUserIds.count)")
            print("FollowingFeedViewModel: User IDs: \(allUserIds)")

            guard !allUserIds.isEmpty else {
                self.posts = []
                if initial { self.isLoading = false } else { self.isFetchingMore = false }
                self.canLoadMore = false // Kullanıcı kimseyi takip etmiyorsa daha fazla post olamaz
                print("User is not following anyone.")
                return
            }
            
            // Firestore 'in' sorgusu limiti (30). Bu limiti aşan kullanıcılar için sadece ilk 30 kişi dikkate alınır.
            let limitedUserIds = Array(allUserIds.prefix(30))
            if allUserIds.count > 30 {
                print("FollowingFeedViewModel: Warning - User follows >30 people. Querying posts for first 30 only due to Firestore limits.")
            }

            // 2. Firestore Sorgusunu Oluştur
            var query: Query = self.db.collection("posts")
                .whereField("userId", in: limitedUserIds)
                .order(by: "timestamp", descending: true) // En yeniden eskiye sırala
                .limit(to: self.postsPerBatch)

            // Eğer daha fazla yükleme yapılıyorsa, son belgeden sonrasını iste
            if let lastSnapshot = self.lastDocumentSnapshot, !initial {
                query = query.start(afterDocument: lastSnapshot)
            }

            // 3. Sorguyu Çalıştır (getDocuments ile, listener yok)
            query.getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    self.errorMessage = "Gönderiler yüklenirken hata oluştu: \(error.localizedDescription)"
                    print("Error fetching posts: \(error.localizedDescription)")
                } else if let snapshot = querySnapshot {
                    print("FollowingFeedViewModel: Fetched \(snapshot.documents.count) documents.")
                    // Yeni postları işle ve ekle/ata
                    let newPosts = snapshot.documents.compactMap { document -> Post? in
                        Post(id: document.documentID, data: document.data())
                    }
                    
                    // Son belgeyi güncelle
                    self.lastDocumentSnapshot = snapshot.documents.last
                    
                    // Daha fazla gönderi olup olmadığını kontrol et (çekilen belge sayısı limitten azsa sona ulaşıldı)
                    self.canLoadMore = snapshot.documents.count >= self.postsPerBatch
                    
                    if initial {
                        self.posts = newPosts
                    } else {
                        self.posts.append(contentsOf: newPosts)
                    }
                    self.errorMessage = nil // Başarılı olduysa hatayı temizle
                } else {
                    print("FollowingFeedViewModel: No snapshot received, assuming end reached.")
                    self.canLoadMore = false // Snapshot yoksa daha fazla yüklenemez
                    self.lastDocumentSnapshot = nil // Snapshot yoksa referansı sıfırla
                }

                // Yükleme durumunu güncelle
                if initial { self.isLoading = false } else { self.isFetchingMore = false }
            }
        }
    }
    
    // View tarafından çağrılacak fonksiyon (listenin sonuna gelindiğinde)
    func loadMoreIfNeeded(currentItem post: Post?) {
        // Eğer posts boşsa veya currentItem nil ise bir şey yapma
        guard let post = post, !posts.isEmpty else { return }

        // Listenin sonuna gelinip gelinmediğini kontrol et (örn. sondan 5. eleman göründüğünde)
        let thresholdIndex = posts.index(posts.endIndex, offsetBy: -5)
        if posts.firstIndex(where: { $0.id == post.id }) == thresholdIndex {
            fetchPosts(initial: false)
        }
    }
}

// Array chunking extension - Projede zaten varsa buraya gerek yok
/*
extension Array {
     func chunked(into size: Int) -> [[Element]] {
         return stride(from: 0, to: count, by: size).map {
             Array(self[$0 ..< Swift.min($0 + size, count)])
         }
     }
 }
*/ 

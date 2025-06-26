import Foundation
import FirebaseFirestore

// MARK: - Post Model (Post Modeli)
/// Lorien uygulamasının ana içerik modeli - kullanıcı gönderilerini temsil eder
/// 
/// Bu model şu özellikleri destekler:
/// - Firebase Firestore ile tam entegrasyon
/// - Güvenli veri doğrulama ve hata yönetimi
/// - Eksik alanlar için varsayılan değerler
/// - Alternatif alan adları desteği
/// - Duygu analizi ve reklam meta verileri
/// - Performans optimizasyonu için batch işlemler
///
/// Kullanım örnekleri:
/// ```swift
/// // Firestore'dan tek post oluşturma
/// let post = Post.create(from: documentSnapshot)
///
/// // Birden fazla post oluşturma
/// let posts = Post.createBatch(from: documentSnapshots)
///
/// // Manuel post oluşturma
/// let post = Post(id: "123", userId: "user123", username: "john", content: "Hello!")
/// ```
struct Post: Identifiable, Codable, Hashable, Equatable {
    // MARK: - Static Properties (Statik Özellikler)
    // Uyarı sayacı - production'da log spam'i önlemek için
    private static var categoryWarningCount = 0
    
    // MARK: - Properties (Özellikler)
    var id: String? {
        didSet {
            // ID nil ise veya boşsa, benzersiz bir ID oluştur
            if id == nil || id?.isEmpty == true {
                id = UUID().uuidString
            }
        }
    }
    let userId: String // Post sahibinin kullanıcı ID'si
    let username: String // Post sahibinin kullanıcı adı
    let content: String // Post içeriği (metin)
    var imageUrl: String? // Post görselinin URL'si (opsiyonel)
    var profileImageUrl: String? // Kullanıcı profil resminin URL'si (opsiyonel)
    let timestamp: Date // Post oluşturulma zamanı
    var likes: Int = 0  // Beğeni sayısı - varsayılan değer 0
    var comments: [Comment] = [] // Yorumlar dizisi - varsayılan boş dizi
    var tags: [String] = []  // Etiketler dizisi - varsayılan boş dizi
    var category: String // Post kategorisi: "featured" veya "following"
    var mentions: [String]? // Bahsedilen kullanıcılar (opsiyonel)
    var interests: [String]? // İlgi alanları (opsiyonel)
    var emotionAnalysis: EmotionAnalysis? // Duygu analizi sonucu (opsiyonel)
    var isAd: Bool? = false // Reklam olup olmadığını belirtir
    var adMetadata: AdMetadata? // Reklam meta verilerini tutmak için (opsiyonel)
    let commentsCount: Int // Toplam yorum sayısı
    let likesCount: Int // Toplam beğeni sayısı
    var keywords: [String]? // Anahtar kelimeler (hem metin hem görselden)
    var viewCount: Int = 0 // Görüntülenme sayısı
    
    // MARK: - Computed Properties (Hesaplanmış Özellikler)
    // Benzersiz tanımlayıcı için computed property
    var uniqueId: String {
        return id ?? UUID().uuidString
    }
    
    // MARK: - Time Formatting (Zaman Formatlama)
    // Static relative time formatter - göreceli zaman gösterimi
    var relativeTimeString: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: timestamp, to: now)
        
        if let year = components.year, year >= 1 {
            return "\(year) year\(year == 1 ? "" : "s") ago"
        }
        if let month = components.month, month >= 1 {
            return "\(month) month\(month == 1 ? "" : "s") ago"
        }
        if let week = components.weekOfYear, week >= 1 {
            return "\(week) week\(week == 1 ? "" : "s") ago"
        }
        if let day = components.day, day >= 1 {
            return "\(day) day\(day == 1 ? "" : "s") ago"
        }
        if let hour = components.hour, hour >= 1 {
            return "\(hour) hour\(hour == 1 ? "" : "s") ago"
        }
        if let minute = components.minute, minute >= 1 {
            return "\(minute) minute\(minute == 1 ? "" : "s") ago"
        }
        return "Just now"
    }
    
    // Identifiable protokolü için
    var identifier: String {
        return uniqueId
    }
    
    // MARK: - Coding Keys (Kodlama Anahtarları)
    // Codable protokolü için Firestore alan adlarını tanımlar
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case username
        case content
        case imageUrl
        case profileImageUrl
        case timestamp
        case likes
        case comments
        case tags
        case category
        case mentions
        case interests
        case emotionAnalysis
        case isAd
        case adMetadata
        case commentsCount
        case likesCount
        case keywords
        case viewCount
    }
    
    // MARK: - Decoder Initializer (Çözümleyici Başlatıcısı)
    // JSON/Codable verilerinden Post nesnesi oluşturur
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String?.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        username = try container.decode(String.self, forKey: .username)
        content = try container.decode(String.self, forKey: .content)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        likes = try container.decode(Int.self, forKey: .likes)
        comments = try container.decode([Comment].self, forKey: .comments)
        tags = try container.decode([String].self, forKey: .tags)
        category = try container.decode(String.self, forKey: .category)
        mentions = try container.decode([String]?.self, forKey: .mentions)
        interests = try container.decode([String]?.self, forKey: .interests)
        emotionAnalysis = try container.decodeIfPresent(EmotionAnalysis.self, forKey: .emotionAnalysis)
        isAd = try container.decodeIfPresent(Bool.self, forKey: .isAd)
        adMetadata = try container.decodeIfPresent(AdMetadata.self, forKey: .adMetadata)
        commentsCount = try container.decodeIfPresent(Int.self, forKey: .commentsCount) ?? 0
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords)
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
    }
    
    // MARK: - Encoder Method (Kodlayıcı Metodu)
    // Post nesnesini JSON/Codable formatına çevirir
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(username, forKey: .username)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(likes, forKey: .likes)
        try container.encode(comments, forKey: .comments)
        try container.encode(tags, forKey: .tags)
        try container.encode(category, forKey: .category)
        try container.encode(mentions, forKey: .mentions)
        try container.encode(interests, forKey: .interests)
        try container.encodeIfPresent(emotionAnalysis, forKey: .emotionAnalysis)
        try container.encodeIfPresent(isAd, forKey: .isAd)
        try container.encodeIfPresent(adMetadata, forKey: .adMetadata)
        try container.encode(commentsCount, forKey: .commentsCount)
        try container.encode(likesCount, forKey: .likesCount)
        try container.encodeIfPresent(keywords, forKey: .keywords)
        try container.encode(viewCount, forKey: .viewCount)
    }
    
    // MARK: - Main Initializer (Ana Başlatıcı)
    // Manuel Post nesnesi oluşturmak için kullanılan ana başlatıcı
    init(id: String, userId: String, username: String, content: String, imageUrl: String?, profileImageUrl: String?, timestamp: Date, likes: Int, comments: [Comment], tags: [String], category: String = "featured", mentions: [String]? = nil, interests: [String]? = nil, emotionAnalysis: EmotionAnalysis? = nil, isAd: Bool = false, adMetadata: AdMetadata? = nil) {
        self.id = id
        self.userId = userId
        self.username = username
        self.content = content
        self.imageUrl = imageUrl
        self.profileImageUrl = profileImageUrl
        self.timestamp = timestamp
        self.likes = likes
        self.comments = comments
        self.tags = tags
        self.category = category
        self.mentions = mentions
        self.interests = interests
        self.emotionAnalysis = emotionAnalysis
        self.isAd = isAd
        self.adMetadata = adMetadata
        self.commentsCount = 0
        self.likesCount = 0
        self.viewCount = 0
    }
    
    // MARK: - Equality & Hashable Methods (Eşitlik ve Hashable Metodları)
    // Hashable ve Equatable için gerekli fonksiyonlar
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.uniqueId == rhs.uniqueId &&
               lhs.userId == rhs.userId &&
               lhs.username == rhs.username &&
               lhs.content == rhs.content &&
               lhs.timestamp == rhs.timestamp &&
               lhs.likes == rhs.likes &&
               lhs.comments == rhs.comments &&
               lhs.tags == rhs.tags &&
               lhs.interests == rhs.interests &&
               lhs.imageUrl == rhs.imageUrl &&
               lhs.category == rhs.category &&
               lhs.emotionAnalysis == rhs.emotionAnalysis &&
               lhs.isAd == rhs.isAd &&
               lhs.adMetadata == rhs.adMetadata &&
               lhs.viewCount == rhs.viewCount
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueId)
        hasher.combine(userId)
        hasher.combine(username)
        hasher.combine(content)
        hasher.combine(timestamp)
        hasher.combine(likes)
        hasher.combine(comments)
        hasher.combine(tags)
        hasher.combine(interests)
        hasher.combine(imageUrl)
        hasher.combine(category)
        hasher.combine(emotionAnalysis)
        hasher.combine(isAd)
        hasher.combine(adMetadata)
        hasher.combine(viewCount)
    }

    // MARK: - Firestore Initializer (Firestore Başlatıcısı)
    // Firestore'dan okumak için initializer - eksik veya geçersiz alanları güvenli şekilde işler
    init?(id: String, data: [String: Any]) {
        // MARK: - UserId Validation (Kullanıcı ID Doğrulaması)
        // userId alanını kontrol et - eksik veya boş ise varsayılan değer kullan
        let userId: String
        if let firestoreUserId = data["userId"] as? String, !firestoreUserId.isEmpty {
            userId = firestoreUserId
        } else if let firestoreUserId = data["user_id"] as? String, !firestoreUserId.isEmpty {
            // Alternatif alan adı kontrolü
            userId = firestoreUserId
        } else if let firestoreUserId = data["authorId"] as? String, !firestoreUserId.isEmpty {
            // Başka bir alternatif alan adı
            userId = firestoreUserId
        } else {
            // userId bulunamadıysa varsayılan değer kullan ve uyarı ver
            print("⚠️ Warning: Missing or invalid 'userId' for Post ID: \(id). Using default value.")
            userId = "unknown_user"
        }
        
        // MARK: - Username Validation (Kullanıcı Adı Doğrulaması)
        // username alanını kontrol et
        let username: String
        if let firestoreUsername = data["username"] as? String, !firestoreUsername.isEmpty {
            username = firestoreUsername
        } else if let firestoreUsername = data["author"] as? String, !firestoreUsername.isEmpty {
            // Alternatif alan adı kontrolü
            username = firestoreUsername
        } else {
            // username bulunamadıysa varsayılan değer kullan
            print("⚠️ Warning: Missing or invalid 'username' for Post ID: \(id). Using default value.")
            username = "Unknown User"
        }
        
        // MARK: - Content Validation (İçerik Doğrulaması)
        // content alanını kontrol et
        let content: String
        if let firestoreContent = data["content"] as? String, !firestoreContent.isEmpty {
            content = firestoreContent
        } else if let firestoreContent = data["text"] as? String, !firestoreContent.isEmpty {
            // Alternatif alan adı kontrolü
            content = firestoreContent
        } else if let firestoreContent = data["message"] as? String, !firestoreContent.isEmpty {
            // Başka bir alternatif alan adı
            content = firestoreContent
        } else {
            // content bulunamadıysa varsayılan değer kullan
            print("⚠️ Warning: Missing or invalid 'content' for Post ID: \(id). Using default value.")
            content = "No content available"
        }
        
        // MARK: - Timestamp Validation (Zaman Damgası Doğrulaması)
        // timestamp alanını kontrol et - birden fazla format dene
        var postDate: Date?
        if let timestamp = data["timestamp"] as? Timestamp {
            postDate = timestamp.dateValue()
        } else if let timestampString = data["timestamp"] as? String {
            postDate = Post.parseDate(from: timestampString)
        } else if let createdAtTimestamp = data["created_at"] as? Timestamp {
            postDate = createdAtTimestamp.dateValue()
        } else if let createdAtString = data["created_at"] as? String {
            postDate = Post.parseDate(from: createdAtString)
        } else if let createdAtTimestamp = data["createdAt"] as? Timestamp {
            postDate = createdAtTimestamp.dateValue()
        } else if let createdAtString = data["createdAt"] as? String {
            postDate = Post.parseDate(from: createdAtString)
        }
        
        // timestamp bulunamadıysa güncel tarihi kullan
        if postDate == nil {
            print("⚠️ Warning: Missing or invalid 'timestamp' for Post ID: \(id). Using current date.")
            postDate = Date()
        }
        
        // MARK: - Likes Validation (Beğeni Doğrulaması)
        // likes alanını kontrol et
        let likes: Int
        if let firestoreLikes = data["likes"] as? Int {
            likes = firestoreLikes
        } else if let firestoreLikes = data["likeCount"] as? Int {
            // Alternatif alan adı kontrolü
            likes = firestoreLikes
        } else {
            // likes bulunamadıysa varsayılan değer kullan
            print("⚠️ Warning: Missing or invalid 'likes' for Post ID: \(id). Using default value 0.")
            likes = 0
        }
        
        // MARK: - Tags Validation (Etiket Doğrulaması)
        // tags alanını kontrol et
        let tags: [String]
        if let firestoreTags = data["tags"] as? [String] {
            tags = firestoreTags
        } else if let firestoreTags = data["categories"] as? [String] {
            // Alternatif alan adı kontrolü
            tags = firestoreTags
        } else {
            // tags bulunamadıysa boş dizi kullan
            print("⚠️ Warning: Missing or invalid 'tags' for Post ID: \(id). Using empty array.")
            tags = []
        }
        
        // MARK: - Category Validation (Kategori Doğrulaması)
        // category alanını kontrol et
        let category: String
        if let firestoreCategory = data["category"] as? String, !firestoreCategory.isEmpty {
            category = firestoreCategory
        } else if let firestoreCategory = data["type"] as? String, !firestoreCategory.isEmpty {
            // Alternatif alan adı kontrolü
            category = firestoreCategory
        } else {
            // category bulunamadıysa varsayılan değer kullan
            // Uyarıyı sadece debug modunda veya ilk birkaç kez göster
            #if DEBUG
            print("⚠️ Warning: Missing or invalid 'category' for Post ID: \(id). Using default value 'featured'.")
            #else
            // Production'da sadece ilk 5 uyarıyı göster
            if Post.categoryWarningCount < 5 {
                print("⚠️ Warning: Missing or invalid 'category' for Post ID: \(id). Using default value 'featured'.")
                Post.categoryWarningCount += 1
            } else if Post.categoryWarningCount == 5 {
                print("ℹ️ Info: Category warnings suppressed. Using default 'featured' for remaining posts.")
                Post.categoryWarningCount += 1
            }
            #endif
            category = "featured"
        }
        
        // MARK: - Optional Fields (Opsiyonel Alanlar)
        // Diğer opsiyonel alanları güvenli şekilde al
        let commentsCount = data["commentsCount"] as? Int ?? data["commentCount"] as? Int ?? 0
        let likesCount = data["likesCount"] as? Int ?? likes // likes alanını kullan
        let imageUrl = data["imageUrl"] as? String ?? data["image"] as? String
        let profileImageUrl = data["profileImageUrl"] as? String ?? data["profileImage"] as? String
        let mentions = data["mentions"] as? [String]
        let interests = data["interests"] as? [String]
        let keywords = data["keywords"] as? [String]
        let viewCount = data["viewCount"] as? Int ?? data["views"] as? Int ?? 0
        
        // MARK: - Complex Objects (Karmaşık Nesneler)
        // EmotionAnalysis ve AdMetadata gibi karmaşık nesneleri güvenli şekilde parse et
        let emotionAnalysis = (data["emotionAnalysis"] as? [String: Any]).flatMap { EmotionAnalysis(data: $0) }
        let isAd = data["isAd"] as? Bool ?? data["isAdvertisement"] as? Bool ?? false
        let adMetadata = (data["adMetadata"] as? [String: Any]).flatMap { AdMetadata(data: $0) }
        
        // MARK: - Object Initialization (Nesne Başlatma)
        // Tüm alanları doğruladıktan sonra nesneyi oluştur
        self.id = id
        self.userId = userId
        self.username = username
        self.content = content
        self.imageUrl = imageUrl
        self.profileImageUrl = profileImageUrl
        self.timestamp = postDate ?? Date()
        self.likes = likes
        self.comments = [] // Firestore'dan comments ayrı olarak yüklenir
        self.tags = tags
        self.category = category
        self.mentions = mentions
        self.interests = interests
        self.emotionAnalysis = emotionAnalysis
        self.isAd = isAd
        self.adMetadata = adMetadata
        self.commentsCount = commentsCount
        self.likesCount = likesCount
        self.keywords = keywords
        self.viewCount = viewCount
        
        // MARK: - Success Log (Başarı Logu)
        // Başarılı oluşturma durumunda log ver
        print("✅ Successfully created Post object for ID: \(id) with userId: \(userId)")
    }

    // MARK: - RecommendedItem Initializer (Önerilen Öğe Başlatıcısı)
    // RecommendedItem'dan Post oluşturmak için (reklamlar için)
    init(from recommendedItem: RecommendedItem) {
        // MARK: - Basic Fields Assignment (Temel Alan Atamaları)
        // Önce basit ve zorunlu alanları ata
        self.id = recommendedItem.id
        self.userId = recommendedItem.userId ?? "advertisement_user"
        self.username = recommendedItem.username ?? "Sponsorlu"
        self.content = recommendedItem.content ?? "Sponsorlu içerik"
        self.imageUrl = nil // API yanıtında reklamlar için görsel URL'si yok varsayalım
        self.likes = recommendedItem.likes ?? 0 // API'den gelen likes değerini ata
        self.comments = recommendedItem.comments?.compactMap { apiComment -> Comment? in
            guard let content = apiComment.content,
                  let userId = apiComment.userId,
                  let username = apiComment.username else { return nil }
            
            let timestamp = Post.parseDate(from: apiComment.timestamp)
            
            return Comment(
                id: apiComment.id ?? UUID().uuidString,
                postId: recommendedItem.id,
                userId: userId,
                username: username,
                content: content,
                timestamp: timestamp
            )
        } ?? []
        self.tags = recommendedItem.tags ?? []
        self.category = "advertisement"
        self.mentions = [] // Reklamlar için mention yok varsayalım
        self.interests = recommendedItem.interests ?? []
        self.isAd = true
        self.adMetadata = recommendedItem.adMetadata
        self.commentsCount = recommendedItem.commentsCount ?? recommendedItem.comments?.count ?? 0 // Önce commentsCount'u dene, yoksa comments dizisinin uzunluğunu kullan
        self.likesCount = self.likes // likes alanına atanan değeri kullan

        // MARK: - Helper Function Fields (Yardımcı Fonksiyon Alanları)
        // Şimdi helper fonksiyonları kullanan alanları ata
        // timestamp, parseEmotionData'dan önce atanmalı
        self.timestamp = Post.parseDate(from: recommendedItem.timestamp ?? recommendedItem.createdAt ?? "")
        self.emotionAnalysis = parseEmotionData(from: recommendedItem.emotionAnalysis)
        self.keywords = recommendedItem.keywords
        self.viewCount = 0
    }

    // MARK: - Firestore Dictionary Conversion (Firestore Sözlük Dönüşümü)
    // Firestore'a yazmak için dictionary formatına çevirir
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "username": username,
            "content": content,
            "timestamp": Timestamp(date: timestamp),
            "likes": likes,
            "tags": tags,
            "category": category,
            "mentions": mentions ?? [],
            "interests": interests ?? [],
            "isAd": isAd ?? false,
            "commentsCount": commentsCount,
            "likesCount": likesCount,
            "viewCount": viewCount
        ]
        // id alanını Firestore'a yüklemiyoruz, otomatik olarak yönetilecek
        if let imageUrl = imageUrl { dict["imageUrl"] = imageUrl }
        if let profileImageUrl = profileImageUrl { dict["profileImageUrl"] = profileImageUrl }
        if let adMetadata = adMetadata { dict["adMetadata"] = adMetadata.toDictionary() }
        if let emotionAnalysis = emotionAnalysis { dict["emotionAnalysis"] = emotionAnalysis.toDictionary() }
        if let keywords = keywords { dict["keywords"] = keywords }
        return dict
    }
    
    // MARK: - Date Parsing Utility (Tarih Ayrıştırma Yardımcısı)
    // Helper: Tarih string'ini Date'e çevirme - birden fazla format destekler
    static func parseDate(from dateString: String?) -> Date {
        guard let dateString = dateString else { return Date() }
        
        // Format 1: ISO8601 (API veya diğer sistemlerden gelebilir)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        isoFormatter.formatOptions = .withInternetDateTime
         if let date = isoFormatter.date(from: dateString) {
            return date
        }

        // Format 2: Firestore String (Örnekteki gibi) - Locale önemlidir!
        let firestoreFormatter = DateFormatter()
        firestoreFormatter.dateFormat = "MMM d, yyyy 'at' h:mm:ss a z" // Örneğin "April 5, 2025 at 11:29:53 AM UTC"
        firestoreFormatter.locale = Locale(identifier: "en_US_POSIX") // Formatın dilinden bağımsız olması için
        if let date = firestoreFormatter.date(from: dateString) {
           return date
        }
        
        // Format 3: Başka bir olası format (Örnek: "yyyy-MM-dd HH:mm:ss Z")
        let standardFormatter = DateFormatter()
        standardFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        standardFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = standardFormatter.date(from: dateString) {
             return date
        }

         print("Could not parse date string: \(dateString) with known formats.")
        return Date() // Ayrıştırma başarısız olursa güncel tarihi dön
    }

    // MARK: - Emotion Data Parsing (Duygu Verisi Ayrıştırma)
    // Helper: API'den gelen EmotionData'yı EmotionAnalysis modeline çevirme
    private func parseEmotionData(from emotionData: EmotionData?) -> EmotionAnalysis? {
        guard let data = emotionData else { return nil }
        return EmotionAnalysis(
            emotion: data.emotion ?? "Unknown",
            confidence: data.confidence ?? 0.0,
            timestamp: Post.parseDate(from: data.timestamp)
        )
    }

    // MARK: - Firestore Document Creation (Firestore Doküman Oluşturma)
    // Firestore'dan daha güvenli veri oluşturma için statik yardımcı fonksiyon
    static func create(from document: DocumentSnapshot) -> Post? {
        // MARK: - Document Data Check (Doküman Veri Kontrolü)
        guard let data = document.data() else {
            print("❌ Error: No data found in document \(document.documentID)")
            return nil
        }
        
        // MARK: - Post Creation Attempt (Post Oluşturma Denemesi)
        // Güvenli şekilde Post oluştur
        guard let post = Post(id: document.documentID, data: data) else {
            print("❌ Error: Failed to create Post object from document \(document.documentID)")
            print("📊 Document data keys: \(data.keys.sorted())")
            return nil
        }
        
        // MARK: - Success Log (Başarı Logu)
        print("✅ Successfully created Post from Firestore document: \(document.documentID)")
        return post
    }
    
    // MARK: - Batch Post Creation (Toplu Post Oluşturma)
    // Birden fazla Firestore dokümanından Post dizisi oluşturma
    static func createBatch(from documents: [DocumentSnapshot]) -> [Post] {
        var posts: [Post] = []
        var successCount = 0
        var errorCount = 0
        
        for document in documents {
            if let post = create(from: document) {
                posts.append(post)
                successCount += 1
            } else {
                errorCount += 1
            }
        }
        
        // MARK: - Batch Results Log (Toplu Sonuç Logu)
        print("📊 Batch Post creation completed:")
        print("   ✅ Successfully created: \(successCount) posts")
        print("   ❌ Failed to create: \(errorCount) posts")
        print("   📈 Success rate: \(successCount > 0 ? Double(successCount) / Double(successCount + errorCount) * 100 : 0)%")
        
        return posts
    }
} 

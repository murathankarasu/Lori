import Foundation
import FirebaseFirestore

struct Post: Identifiable, Codable, Hashable, Equatable {
    @DocumentID var id: String?
    let userId: String
    let username: String
    let content: String
    var imageUrl: String?
    var profileImageUrl: String?
    let timestamp: Date
    var likes: Int
    var comments: [Comment]
    var tags: [String]
    var category: String // "featured" veya "following"
    var mentions: [String]?
    var interests: [String]?
    var emotionAnalysis: EmotionAnalysis?
    var isAd: Bool? = false // Reklam olup olmadığını belirtir
    var adMetadata: AdMetadata? // Reklam meta verilerini tutmak için (opsiyonel)
    let commentsCount: Int
    let likesCount: Int
    var keywords: [String]? // Anahtar kelimeler (hem metin hem görselden)
    
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
    }
    
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
    }
    
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
    }
    
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
    }
    
    // Hashable ve Equatable için gerekli fonksiyonlar
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id &&
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
               lhs.adMetadata == rhs.adMetadata
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
    }

    // Firestore'dan okumak için initializer
    init?(id: String, data: [String: Any]) {
        guard let userId = data["userId"] as? String else {
            print("Error creating Post (ID: \(id)): Missing or invalid 'userId'")
            self.id = id
            self.userId = ""
            self.username = ""
            self.content = ""
            self.imageUrl = nil
            self.profileImageUrl = nil
            self.timestamp = Date()
            self.likes = 0
            self.comments = []
            self.tags = []
            self.category = "featured"
            self.mentions = nil
            self.interests = nil
            self.emotionAnalysis = nil
            self.isAd = false
            self.adMetadata = nil
            self.commentsCount = 0
            self.likesCount = 0
            self.keywords = nil
            return nil
        }
        guard let username = data["username"] as? String else {
            print("Error creating Post (ID: \(id)): Missing or invalid 'username'")
            self.id = id
            self.userId = userId
            self.username = ""
            self.content = ""
            self.imageUrl = nil
            self.profileImageUrl = nil
            self.timestamp = Date()
            self.likes = 0
            self.comments = []
            self.tags = []
            self.category = "featured"
            self.mentions = nil
            self.interests = nil
            self.emotionAnalysis = nil
            self.isAd = false
            self.adMetadata = nil
            self.commentsCount = 0
            self.likesCount = 0
            self.keywords = nil
            return nil
        }
        guard let content = data["content"] as? String else {
            print("Error creating Post (ID: \(id)): Missing or invalid 'content'")
            self.id = id
            self.userId = userId
            self.username = username
            self.content = ""
            self.imageUrl = nil
            self.profileImageUrl = nil
            self.timestamp = Date()
            self.likes = 0
            self.comments = []
            self.tags = []
            self.category = "featured"
            self.mentions = nil
            self.interests = nil
            self.emotionAnalysis = nil
            self.isAd = false
            self.adMetadata = nil
            self.commentsCount = 0
            self.likesCount = 0
            self.keywords = nil
            return nil
        }
        var postDate: Date?
        if let timestamp = data["timestamp"] as? Timestamp {
            postDate = timestamp.dateValue()
        } else if let timestampString = data["timestamp"] as? String {
            postDate = Post.parseDate(from: timestampString)
        } else if let createdAtTimestamp = data["created_at"] as? Timestamp {
            postDate = createdAtTimestamp.dateValue()
        }
        guard let finalTimestamp = postDate else {
            print("Error creating Post (ID: \(id)): Missing or invalid 'timestamp' or 'created_at'")
            self.id = id
            self.userId = userId
            self.username = username
            self.content = content
            self.imageUrl = nil
            self.profileImageUrl = nil
            self.timestamp = Date()
            self.likes = 0
            self.comments = []
            self.tags = []
            self.category = "featured"
            self.mentions = nil
            self.interests = nil
            self.emotionAnalysis = nil
            self.isAd = false
            self.adMetadata = nil
            self.commentsCount = 0
            self.likesCount = 0
            self.keywords = nil
            return nil
        }
        guard let likes = data["likes"] as? Int else {
            print("Error creating Post (ID: \(id)): Missing or invalid 'likes'")
            self.id = id
            self.userId = userId
            self.username = username
            self.content = content
            self.imageUrl = nil
            self.profileImageUrl = nil
            self.timestamp = finalTimestamp
            self.likes = 0
            self.comments = []
            self.tags = []
            self.category = "featured"
            self.mentions = nil
            self.interests = nil
            self.emotionAnalysis = nil
            self.isAd = false
            self.adMetadata = nil
            self.commentsCount = 0
            self.likesCount = 0
            self.keywords = nil
            return nil
        }
        guard let tags = data["tags"] as? [String] else {
            print("Error creating Post (ID: \(id)): Missing or invalid 'tags'")
            self.id = id
            self.userId = userId
            self.username = username
            self.content = content
            self.imageUrl = nil
            self.profileImageUrl = nil
            self.timestamp = finalTimestamp
            self.likes = likes
            self.comments = []
            self.tags = []
            self.category = "featured"
            self.mentions = nil
            self.interests = nil
            self.emotionAnalysis = nil
            self.isAd = false
            self.adMetadata = nil
            self.commentsCount = 0
            self.likesCount = 0
            self.keywords = nil
            return nil
        }
        let category = data["category"] as? String ?? "featured"
        let commentsCount = data["commentsCount"] as? Int ?? 0
        let likesCount = data["likesCount"] as? Int ?? 0
        let imageUrl = data["imageUrl"] as? String
        let profileImageUrl = data["profileImageUrl"] as? String
        self.id = id
        self.userId = userId
        self.username = username
        self.content = content
        self.imageUrl = imageUrl
        self.profileImageUrl = profileImageUrl
        self.timestamp = finalTimestamp
        self.likes = likes
        self.comments = []
        self.tags = tags
        self.category = category
        self.mentions = data["mentions"] as? [String]
        self.interests = data["interests"] as? [String]
        self.emotionAnalysis = (data["emotionAnalysis"] as? [String: Any]).flatMap { EmotionAnalysis(data: $0) }
        self.isAd = data["isAd"] as? Bool
        self.adMetadata = (data["adMetadata"] as? [String: Any]).flatMap { AdMetadata(data: $0) }
        self.commentsCount = commentsCount
        self.likesCount = likesCount
        self.keywords = data["keywords"] as? [String]
    }

    // RecommendedItem'dan Post oluşturmak için (reklamlar için)
    init(from recommendedItem: RecommendedItem) {
        // Önce basit ve zorunlu alanları ata
        self.id = recommendedItem.id
        self.userId = recommendedItem.userId ?? "advertisement_user"
        self.username = recommendedItem.username ?? "Sponsorlu"
        self.content = recommendedItem.content
        self.imageUrl = nil // API yanıtında reklamlar için görsel URL'si yok varsayalım
        self.likes = recommendedItem.likes ?? 0 // API'den gelen likes değerini ata
        self.comments = [] // Reklamlar için yorumları boş başlat
        self.tags = recommendedItem.tags ?? []
        self.category = "advertisement"
        self.mentions = [] // Reklamlar için mention yok varsayalım
        self.interests = recommendedItem.interests ?? []
        self.isAd = true
        self.adMetadata = recommendedItem.adMetadata
        self.commentsCount = recommendedItem.commentsCount ?? 0 // API'den gelen count'u ata
        self.likesCount = self.likes // likes alanına atanan değeri kullan

        // Şimdi helper fonksiyonları kullanan alanları ata
        // timestamp, parseEmotionData'dan önce atanmalı
        self.timestamp = Post.parseDate(from: recommendedItem.timestamp ?? recommendedItem.createdAt)
        self.emotionAnalysis = parseEmotionData(from: recommendedItem.emotionAnalysis)
        self.keywords = recommendedItem.keywords
    }

    // Firestore'a yazmak için dictionary
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
            "likesCount": likesCount
        ]
        if let imageUrl = imageUrl { dict["imageUrl"] = imageUrl }
        if let profileImageUrl = profileImageUrl { dict["profileImageUrl"] = profileImageUrl }
        if let adMetadata = adMetadata { dict["adMetadata"] = adMetadata.toDictionary() }
        if let emotionAnalysis = emotionAnalysis { dict["emotionAnalysis"] = emotionAnalysis.toDictionary() }
        if let keywords = keywords { dict["keywords"] = keywords }
        return dict
    }
    
    // Helper: Tarih string'ini Date'e çevirme (Örnek)
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

    // Helper: API'den gelen EmotionData'yı EmotionAnalysis modeline çevirme (Örnek)
    private func parseEmotionData(from emotionData: EmotionData?) -> EmotionAnalysis? {
        guard let data = emotionData else { return nil }
        return EmotionAnalysis(
            emotion: data.emotion ?? "Unknown",
            confidence: data.confidence ?? 0.0,
            timestamp: Post.parseDate(from: data.timestamp)
        )
    }
} 

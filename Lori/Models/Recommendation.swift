import Foundation

// Recommendation API'den dönen ana yanıt yapısı
struct RecommendationResponse: Codable {
    let emotionPattern: [String: Double]? // Opsiyonel, emotion_pattern her zaman gelmeyebilir
    let recommendations: [RecommendedItem]
    let success: Bool
}

// Yorum verisi için özel bir yapı - API'den gelecek temel alanları içerir
struct APIComment: Codable {
    let id: String?
    let content: String?
    let userId: String?
    let username: String?
    let timestamp: String?
    
    // Diğer alanlar eksik olabilir, gerekirse eklenebilir
    
    // String dizisinden gelen yorumları işleyebilmek için özel bir initializer
    init(from decoder: Decoder) throws {
        // İlk olarak tüm değişkenleri nil olarak başlat
        var tempId: String? = nil
        var tempContent: String? = nil
        var tempUserId: String? = nil
        var tempUsername: String? = nil
        var tempTimestamp: String? = nil
        
        do {
            // Önce standart Codable yöntemiyle ayrıştırmayı dene
            let container = try decoder.container(keyedBy: CodingKeys.self)
            tempId = try container.decodeIfPresent(String.self, forKey: .id)
            tempContent = try container.decodeIfPresent(String.self, forKey: .content)
            tempUserId = try container.decodeIfPresent(String.self, forKey: .userId)
            tempUsername = try container.decodeIfPresent(String.self, forKey: .username)
            tempTimestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
        } catch {
            // Eğer standart ayrıştırma başarısız olursa, muhtemelen bir String'dir
            // String'i içerik olarak kullan, diğer alanları null bırak
            do {
                let container = try decoder.singleValueContainer()
                tempContent = try container.decode(String.self)
            } catch {
                // Hem nesne hem string olarak ayrıştırma başarısız olursa
                // Değerler zaten nil olduğu için bir şey yapmaya gerek yok
            }
        }
        
        // Geçici değerleri kalıcı değişkenlere ata
        self.id = tempId
        self.content = tempContent
        self.userId = tempUserId
        self.username = tempUsername
        self.timestamp = tempTimestamp
    }
}

// Hem post hem de reklam olabilen önerilen öğe yapısı
struct RecommendedItem: Codable, Identifiable {
    let id: String
    let content: String?
    let createdAt: String?
    let emotion: String?
    let emotionAnalysis: EmotionData?
    let interests: [String]?
    let likes: Int?
    let tags: [String]?
    let timestamp: String?
    let userId: String?
    let username: String?
    let comments: [APIComment]?
    let keywords: [String]?
    let commentsCount: Int? // Yeni alan: Yorum sayısı için

    // Reklam özel alanları
    let isAd: Bool?
    let adMetadata: AdMetadata?

    enum CodingKeys: String, CodingKey {
        case id, content, emotion, emotionAnalysis, interests, likes, tags, timestamp, userId, username, comments, keywords, createdAt, isAd, adMetadata, commentsCount
    }

    // Helper: Bu öğenin reklam olup olmadığını kontrol eder
    var isAdvertisement: Bool {
        return isAd == true
    }
    
    // Özel decoder implementasyonu
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Zorunlu alanlar
        id = try container.decode(String.self, forKey: .id)
        
        // Opsiyonel alanlar
        content = try container.decodeIfPresent(String.self, forKey: .content)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        emotion = try container.decodeIfPresent(String.self, forKey: .emotion)
        emotionAnalysis = try container.decodeIfPresent(EmotionData.self, forKey: .emotionAnalysis)
        interests = try container.decodeIfPresent([String].self, forKey: .interests)
        likes = try container.decodeIfPresent(Int.self, forKey: .likes)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords)
        isAd = try container.decodeIfPresent(Bool.self, forKey: .isAd)
        adMetadata = try container.decodeIfPresent(AdMetadata.self, forKey: .adMetadata)
        commentsCount = try container.decodeIfPresent(Int.self, forKey: .commentsCount)
        
        // Comments alanını özel olarak işle
        do {
            comments = try container.decodeIfPresent([APIComment].self, forKey: .comments)
        } catch {
            // Eğer comments bir dizi değilse, boş dizi olarak ayarla
            comments = []
        }
    }
}

// Reklam meta verisi
struct AdMetadata: Codable, Equatable, Hashable {
    let advertiserId: String?
    let campaignId: String?
    let priority: Double?
    let targetEmotions: [String]?

    // CodingKeys'e gerek yok, RecommendationService'de keyDecodingStrategy kullanıyoruz
    enum CodingKeys: String, CodingKey {
        case advertiserId, campaignId, priority, targetEmotions
    }

    // Firestore dictionary'sinden initializer
    init?(data: [String: Any]) {
        self.advertiserId = data["advertiser_id"] as? String
        self.campaignId = data["campaign_id"] as? String
        self.priority = data["priority"] as? Double
        self.targetEmotions = data["target_emotions"] as? [String]
    }
    
    // Firestore'a yazmak için dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let advertiserId = advertiserId { dict["advertiser_id"] = advertiserId }
        if let campaignId = campaignId { dict["campaign_id"] = campaignId }
        if let priority = priority { dict["priority"] = priority }
        if let targetEmotions = targetEmotions { dict["target_emotions"] = targetEmotions }
        return dict
    }
}

// EmotionAnalysis verisi (API yanıtına uygun)
struct EmotionData: Codable {
    let confidence: Double?
    let emotion: String?
    let timestamp: String? // Tarih formatı
}

// TODO: API'den gelen tarih String'lerini Date nesnesine çevirmek için DateFormatter veya ISO8601DateFormatter kullanılabilir.
// Post modelini de API'den gelen tüm alanları içerecek şekilde güncellemek veya API verisini Post'a map'leyen bir mekanizma kurmak gerekebilir.
// Özellikle 'comments' alanı API'de string dizisi olarak geliyor, Firestore'da Comment nesneleri tutuluyorsa uyumlaştırma lazım. 
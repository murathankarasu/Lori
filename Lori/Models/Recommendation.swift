import Foundation

// Recommendation API'den dönen ana yanıt yapısı
struct RecommendationResponse: Codable {
    let emotionPattern: [String: Double]? // Opsiyonel, emotion_pattern her zaman gelmeyebilir
    let recommendations: [RecommendedItem]
    let success: Bool
}

// Hem post hem de reklam olabilen önerilen öğe yapısı
struct RecommendedItem: Codable, Identifiable {
    let id: String // Firestore document ID veya reklam ID'si
    let content: String? // API'den gelen yanıtta content bazen eksik olabilir, bu yüzden opsiyonel yapıldı
    let createdAt: String? // API'deki tarih formatı Date'e çevrilmeli veya String tutulmalı
    let emotion: String?
    let emotionAnalysis: EmotionData?
    let interests: [String]?
    let likes: Int?
    let tags: [String]?
    let timestamp: String? // API'deki tarih formatı Date'e çevrilmeli veya String tutulmalı
    let userId: String?
    let username: String?
    let comments: [String]? // Yorum içerikleri yerine ID'leri veya Comment nesneleri olabilir
    let commentsCount: Int?
    let keywords: [String]?

    // Reklam özel alanları
    let isAd: Bool?
    let adMetadata: AdMetadata?

    // CodingKeys artık gerekli değil çünkü RecommendationService'de keyDecodingStrategy kullanıyoruz
    // Ama geriye dönük uyumluluk için tutalım
    enum CodingKeys: String, CodingKey {
        case id, content, emotion, emotionAnalysis, interests, likes, tags, timestamp, userId, username, comments, commentsCount, keywords, createdAt, isAd, adMetadata
    }

    // Helper: Bu öğenin reklam olup olmadığını kontrol eder
    var isAdvertisement: Bool {
        return isAd == true
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
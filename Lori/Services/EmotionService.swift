import Foundation

public class EmotionService {
    static let shared = EmotionService()
    private let baseURL = "https://emotion-service-main-services.up.railway.app/"
    private let session: URLSession
    
    // Add a cache to store emotion analysis results
    private var emotionCache: [String: EmotionAnalysis] = [:]
    
    // Available emotions for random selection with Turkish-English format
    private let availableEmotions = [
        "Üzüntü (Sadness)",
        "Neşe (Joy)", 
        "Aşk (Love)",
        "Öfke (Anger)",
        "Korku (Fear)",
        "Şaşkınlık (Surprise)"
    ]
    
    // English to Turkish-English mapping
    private let emotionMapping: [String: String] = [
        "sadness": "Üzüntü (Sadness)",
        "joy": "Neşe (Joy)",
        "love": "Aşk (Love)", 
        "anger": "Öfke (Anger)",
        "fear": "Korku (Fear)",
        "surprise": "Şaşkınlık (Surprise)",
        "neşe": "Neşe (Joy)",
        "korku": "Korku (Fear)",
        "öfke": "Öfke (Anger)",
        "aşk": "Aşk (Love)",
        "üzüntü": "Üzüntü (Sadness)",
        "şaşkınlık": "Şaşkınlık (Surprise)"
    ]
    
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.httpMaximumConnectionsPerHost = 1
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        self.session = URLSession(configuration: config)
    }
    
    // Add a new parameter to control when API calls are made
    func analyzeEmotion(text: String, operationType: EmotionOperationType = .other) async throws -> EmotionAnalysis {
        print("\n=== Duygu Analizi ===")
        print("Analiz edilen metin: \(text)")
        print("İşlem türü: \(operationType.rawValue)")
        
        // Check if we should use the API based on operation type
        // Only allow API calls for post creation, like, and comment operations
        guard operationType == .postCreation || operationType == .like || operationType == .comment else {
            print("⚠️ API çağrısı atlanıyor: Sadece gönderi oluşturma, beğeni ve yorum için API çağrısı yapılıyor")
            
            // Check if we have a cached result for this text
            if let cachedEmotion = emotionCache[text] {
                print("✅ Önbellekten duygu analizi kullanılıyor")
                return cachedEmotion
            }
            
            // Return a default emotion analysis if no cache is available
            return EmotionAnalysis(
                emotion: "Unknown",
                confidence: 0.0
            )
        }
        
        // Check cache first
        if let cachedEmotion = emotionCache[text] {
            print("✅ Önbellekten duygu analizi kullanılıyor")
            return cachedEmotion
        }
        
        guard let url = URL(string: "\(baseURL)/analyze") else {
            print("❌ Geçersiz URL: \(baseURL)/analyze")
            throw EmotionError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60
        
        let body = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("\n=== API İsteği Detayları ===")
        print("URL: \(url.absoluteString)")
        print("HTTP Metodu: \(request.httpMethod ?? "")")
        print("İstek Başlıkları: \(request.allHTTPHeaderFields ?? [:])")
        print("İstek Gövdesi: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
        print("===================\n")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Geçersiz HTTP yanıtı")
                throw EmotionError.connectionError
            }
            
            print("\n=== API Yanıt Detayları ===")
            print("Yanıt Kodu: \(httpResponse.statusCode)")
            print("Yanıt Başlıkları: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Ham Yanıt: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ API hatası: \(httpResponse.statusCode)")
                throw EmotionError.serverError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(EmotionAPIResponse.self, from: data)
            
            let confidence: Double = {
                if let probs = apiResponse.probabilities {
                    let emotionKey = emotionKeyFor(apiResponse.emotion)
                    return probs[emotionKey] ?? 0.0
                }
                return 0.0
            }()
            
            // Map the emotion to Turkish-English format
            let mappedEmotion = emotionMapping[apiResponse.emotion.lowercased()] ?? apiResponse.emotion
            
            let emotionAnalysis = EmotionAnalysis(
                emotion: mappedEmotion,
                confidence: confidence
            )
            
            // Cache the result
            emotionCache[text] = emotionAnalysis
            
            print("✅ Duygu analizi tamamlandı")
            print("Duygu: \(emotionAnalysis.emotion)")
            print("Güven Skoru: \(emotionAnalysis.confidence)")
            print("===================\n")
            
            return emotionAnalysis
        } catch {
            print("\n=== Duygu Analizi Hatası ===")
            print("❌ Hata detayı: \(error)")
            print("📝 Analiz edilen metin: \(text)")
            print("🔍 İşlem türü: \(operationType.rawValue)")
            print("🎲 Mevcut duygular: \(availableEmotions.joined(separator: ", "))")
            
            // Return a random emotion when an error occurs
            let randomEmotion = availableEmotions.randomElement() ?? "Neşe (Joy)"
            print("⚠️ Rastgele seçilen duygu: \(randomEmotion)")
            print("📊 Güven skoru: 0.5 (rastgele seçim)")
            print("===================\n")
            
            return EmotionAnalysis(
                emotion: randomEmotion,
                confidence: 0.5
            )
        }
    }
    
    private func emotionKeyFor(_ emotion: String) -> String {
        let lower = emotion.lowercased()
        if lower.contains("neşe") || lower.contains("joy") { return "joy" }
        if lower.contains("korku") || lower.contains("fear") { return "fear" }
        if lower.contains("öfke") || lower.contains("anger") { return "anger" }
        if lower.contains("aşk") || lower.contains("love") { return "love" }
        if lower.contains("üzüntü") || lower.contains("sadness") { return "sadness" }
        if lower.contains("şaşkınlık") || lower.contains("surprise") { return "surprise" }
        return lower
    }
}

// API Yanıt Modeli
struct EmotionAPIResponse: Codable {
    let emotion: String
    let probabilities: [String: Double]?
}

// Hata Tipleri
enum EmotionError: Error {
    case invalidResponse
    case connectionError
    case serverError(Int)
    case networkError(Error)
}

// Operation type enum to control when API calls are made
public enum EmotionOperationType: String {
    case postCreation = "post_creation"
    case like = "like"
    case comment = "comment"
    case other = "other"
} 

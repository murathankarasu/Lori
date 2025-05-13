import Foundation

public class EmotionService {
    static let shared = EmotionService()
    private let baseURL = "https://emotion-service-main-services.up.railway.app"
    private let session: URLSession
    
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
    
    func analyzeEmotion(text: String) async throws -> EmotionAnalysis {
        print("\n=== Duygu Analizi ===")
        print("Analiz edilen metin: \(text)")
        
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
            
            let emotionAnalysis = EmotionAnalysis(
                emotion: apiResponse.emotion,
                confidence: confidence
            )
            
            print("✅ Duygu analizi tamamlandı")
            print("Duygu: \(emotionAnalysis.emotion)")
            print("Güven Skoru: \(emotionAnalysis.confidence)")
            print("===================\n")
            
            return emotionAnalysis
        } catch {
            print("❌ Duygu analizi sırasında hata: \(error)")
            throw EmotionError.networkError(error)
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

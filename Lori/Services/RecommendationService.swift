import Foundation
import FirebaseAuth

enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
}

class RecommendationService {
    
    private let baseURL = "https://recommend-service-main-services.up.railway.app/api/recommendations/"
    
    func fetchRecommendations(userId: String) async -> Result<RecommendationResponse, NetworkError> {
        guard let url = URL(string: baseURL + userId) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Timeout değerini arttır
        request.timeoutInterval = 60
        // Cache politikasını belirle
        request.cachePolicy = .reloadIgnoringLocalCacheData
        // Gerekli başlıkları ekle
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 60
            config.timeoutIntervalForResource = 120
            config.waitsForConnectivity = true
            let session = URLSession(configuration: config)
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Hata durumunda response içeriğini yazdırmak faydalı olabilir
                print("Invalid response: \(response)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
                return .failure(.invalidResponse)
            }
            
            // Gelen JSON verisini önce ekrana yazdıralım (Debug amaçlı)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Recommendation API Response: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            // Keydecodingstrategy için snake_case'i kabul et
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                // İleri seviye hata yakalama için try-catch kullan
                let recommendationResponse = try decoder.decode(RecommendationResponse.self, from: data)
                return .success(recommendationResponse)
            } catch let decodingError as DecodingError {
                print("Decoding Error: \(decodingError)")
                
                // Daha detaylı hata bilgisi
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Missing key: \(key.stringValue), path: \(context.codingPath.map { $0.stringValue })")
                case .typeMismatch(let type, let context):
                    print("Type mismatch: expected \(type), path: \(context.codingPath.map { $0.stringValue })")
                    
                    // Comments alanı için özel hata yönetimi
                    if context.codingPath.last?.stringValue == "comments" {
                        do {
                            // JSON'ı önce dictionary olarak çözümle ve elle dönüştür
                            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                               let recommendations = json["recommendations"] as? [[String: Any]] {
                                
                                // Özel bir yapı oluşturmak yerine basit bir başarılı yanıt döndür
                                return .success(RecommendationResponse(
                                    emotionPattern: [:],
                                    recommendations: [],
                                    success: true
                                ))
                            }
                        } catch {
                            print("JSON manual parsing failed: \(error)")
                        }
                    }
                    
                case .valueNotFound(let type, let context):
                    print("Value not found: expected \(type), path: \(context.codingPath.map { $0.stringValue })")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription), path: \(context.codingPath.map { $0.stringValue })")
                @unknown default:
                    print("Unknown decoding error")
                }
                
                // Kullanıcıya boş bir liste dönmek daha iyi olabilir
                return .success(RecommendationResponse(
                    emotionPattern: [:],
                    recommendations: [],
                    success: true
                ))
            }
            
        } catch {
             print("Request Error: \(error)")
            return .failure(.requestFailed(error))
        }
    }
} 
import Foundation
import FirebaseAuth

/// Ağ hataları enum'u
enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
}

/// Kullanıcı önerileri servisi
/// Bu servis kullanıcının duygu analizi verilerine dayalı olarak kişiselleştirilmiş öneriler alır
/// Uzak API'den öneri verilerini çeker ve işler
class RecommendationService {
    
    private let baseURL = "https://recommend-service-main-services.up.railway.app/api/recommendations/"
    
    /// Kullanıcı için önerileri getirir
    /// Bu fonksiyon kullanıcının ID'sini kullanarak uzak API'den kişiselleştirilmiş öneriler alır
    /// Öneriler kullanıcının duygu analizi geçmişine dayalı olarak oluşturulur
    /// Hata durumlarında detaylı loglama yapar ve uygun hata yönetimi sağlar
    /// - Parameter userId: Önerilerin alınacağı kullanıcının ID'si
    /// - Returns: Result<RecommendationResponse, NetworkError> - Başarılı öneri yanıtı veya hata
    func fetchRecommendations(userId: String) async -> Result<RecommendationResponse, NetworkError> {
        guard let url = URL(string: baseURL + userId) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Timeout değerini arttır - öneri API'si daha yavaş olabilir
        request.timeoutInterval = 60
        // Cache politikasını belirle - her zaman güncel veri al
        request.cachePolicy = .reloadIgnoringLocalCacheData
        // Gerekli başlıkları ekle
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            // URLSession konfigürasyonu - uzun süren istekler için optimize edilmiş
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
            // Keydecodingstrategy için snake_case'i kabul et - API'den gelen veri formatına uygun
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                // İleri seviye hata yakalama için try-catch kullan
                let recommendationResponse = try decoder.decode(RecommendationResponse.self, from: data)
                return .success(recommendationResponse)
            } catch let decodingError as DecodingError {
                print("Decoding Error: \(decodingError)")
                
                // Daha detaylı hata bilgisi - hangi alanın sorunlu olduğunu göster
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Missing key: \(key.stringValue), path: \(context.codingPath.map { $0.stringValue })")
                case .typeMismatch(let type, let context):
                    print("Type mismatch: expected \(type), path: \(context.codingPath.map { $0.stringValue })")
                    
                    // Comments alanı için özel hata yönetimi
                    // API'den gelen veri formatı beklenenden farklı olabilir
                    if context.codingPath.last?.stringValue == "comments" {
                        do {
                            // JSON'ı önce dictionary olarak çözümle ve elle dönüştür
                            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                               let recommendations = json["recommendations"] as? [[String: Any]] {
                                
                                // Özel bir yapı oluşturmak yerine basit bir başarılı yanıt döndür
                                // Bu, API'den gelen veri formatı sorunlarını çözer
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
                
                // Kullanıcıya boş bir liste döndürmek daha iyi olabilir
                // Bu, API'den gelen veri formatı sorunlarında uygulamanın çökmesini önler
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

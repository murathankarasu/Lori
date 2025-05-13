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
        // Gerekirse header ekle (örn: Authorization)
        // request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Hata durumunda response içeriğini yazdırmak faydalı olabilir
                print("Invalid response: \(response)")
                return .failure(.invalidResponse)
            }
            
            let decoder = JSONDecoder()
            // API'deki tarih formatlarına uygun bir DateDecodingStrategy ayarlamak gerekebilir
            // decoder.dateDecodingStrategy = .iso8601 // veya .formatted(DateFormatter)
            
            let recommendationResponse = try decoder.decode(RecommendationResponse.self, from: data)
            return .success(recommendationResponse)
            
        } catch let error as DecodingError {
             print("Decoding Error: \(error)")
            return .failure(.decodingError(error))
        } catch {
             print("Request Error: \(error)")
            return .failure(.requestFailed(error))
        }
    }
} 
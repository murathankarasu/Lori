import Foundation

enum HateSpeechError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
}

class HateSpeechService {
    static let shared = HateSpeechService()
    private let baseURL = "http://localhost:8000/api"
    
    private init() {}
    
    func checkHateSpeech(text: String) async throws -> HateSpeechResponse {
        guard let url = URL(string: "\(baseURL)/check-hate-speech") else {
            throw HateSpeechError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HateSpeechError.serverError("Geçersiz sunucu yanıtı")
            }
            
            guard httpResponse.statusCode == 200 else {
                throw HateSpeechError.serverError("Sunucu hatası: \(httpResponse.statusCode)")
            }
            
            let result = try JSONDecoder().decode(HateSpeechResponse.self, from: data)
            return result
        } catch let error as DecodingError {
            throw HateSpeechError.decodingError(error)
        } catch {
            throw HateSpeechError.networkError(error)
        }
    }
    
    // Gerçek zamanlı kontrol için debounce fonksiyonu
    func debouncedCheck(text: String, delay: TimeInterval = 1.0) async throws -> HateSpeechResponse {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return try await checkHateSpeech(text: text)
    }
} 
import Foundation

class HateSpeechService {
    static let shared = HateSpeechService()
    private let baseURL = "http://192.168.1.45:8000/api"
    private let session: URLSession
    
    private init() {
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
    
    func checkHateSpeech(text: String) async throws -> APIResponse {
        guard let url = URL(string: "\(baseURL)/check-hate-speech") else {
            throw HateSpeechError.invalidResponse
        }
        
        print("\n=== Nefret Söylemi Kontrolü ===")
        print("İstek URL: \(url.absoluteString)")
        print("Gönderilen metin: \(text)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60
        
        let body = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("İstek başlıkları: \(request.allHTTPHeaderFields ?? [:])")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Geçersiz HTTP yanıtı")
            throw HateSpeechError.connectionError
        }
        
        print("Sunucu yanıt kodu: \(httpResponse.statusCode)")
        print("Sunucu yanıt başlıkları: \(httpResponse.allHeaderFields)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("❌ Sunucu hatası: \(httpResponse.statusCode)")
            throw HateSpeechError.serverError(httpResponse.statusCode)
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Sunucu yanıtı: \(responseString)")
        }
        
        let decodedResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        print("✅ İstek başarılı")
        print("Kategori: \(decodedResponse.data.category)")
        print("Güven Skoru: \(decodedResponse.data.confidence)")
        print("Nefret Söylemi mi?: \(decodedResponse.data.isHateSpeech)")
        print("===================\n")
        
        return decodedResponse
    }
    
    func getCategories() async throws -> [String: [String]] {
        guard let url = URL(string: "\(baseURL)/categories") else {
            throw HateSpeechError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60
        
        do {
            print("Kategoriler isteği gönderiliyor: \(url.absoluteString)")
            print("İstek başlıkları: \(request.allHTTPHeaderFields ?? [:])")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HateSpeechError.connectionError
            }
            
            print("Kategoriler sunucu yanıt kodu: \(httpResponse.statusCode)")
            print("Kategoriler sunucu yanıt başlıkları: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Ham kategoriler yanıtı: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("Kategoriler sunucu hatası: \(httpResponse.statusCode)")
                throw HateSpeechError.serverError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(CategoriesResponse.self, from: data)
            
            guard apiResponse.status == "success" else {
                throw HateSpeechError.invalidResponse
            }
            
            return apiResponse.data
            
        } catch let error as HateSpeechError {
            throw error
        } catch {
            print("Kategoriler alınırken hata: \(error)")
            if let urlError = error as? URLError {
                print("URL Hata Detayları:")
                print("- Hata Kodu: \(urlError.code)")
                print("- Hata Açıklaması: \(urlError.localizedDescription)")
                print("- Başarısız URL: \(urlError.failureURLString ?? "Bilinmiyor")")
                
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    throw HateSpeechError.connectionError
                case .timedOut:
                    throw HateSpeechError.serverError(408)
                case .cannotConnectToHost:
                    print("Sunucuya bağlanılamıyor. Lütfen şunları kontrol edin:")
                    print("1. API sunucusu çalışıyor mu?")
                    print("2. Doğru port (8000) kullanılıyor mu?")
                    print("3. Sunucu adresi doğru mu?")
                    throw HateSpeechError.connectionError
                default:
                    throw HateSpeechError.networkError(error)
                }
            } else {
                throw HateSpeechError.networkError(error)
            }
        }
    }
    
    func debouncedCheck(text: String, delay: TimeInterval = 1.0) async throws -> APIResponse {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return try await checkHateSpeech(text: text)
    }
}

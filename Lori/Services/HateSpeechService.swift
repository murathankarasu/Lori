import Foundation

public class HateSpeechService {
    static let shared = HateSpeechService()
    private let baseURL = "http://192.168.1.45:8000/api"
    private let session: URLSession
    private var bannedWords: [String: String] = [:]
    
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
        loadBannedWords()
    }
    
    private func loadBannedWords() {
        guard let path = Bundle.main.path(forResource: "banned_words", ofType: "csv") else {
            print("❌ Yasaklı kelimeler dosyası bulunamadı")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let rows = content.components(separatedBy: .newlines)
            
            for row in rows {
                let columns = row.components(separatedBy: ",")
                if columns.count == 2 {
                    let word = columns[0].lowercased().trimmingCharacters(in: .whitespaces)
                    let category = columns[1].trimmingCharacters(in: .whitespaces)
                    bannedWords[word] = category
                }
            }
            print("✅ Yasaklı kelimeler yüklendi: \(bannedWords.count) kelime")
        } catch {
            print("❌ Yasaklı kelimeler yüklenirken hata: \(error)")
        }
    }
    
    func checkLocalHateSpeech(_ text: String) -> (containsHateSpeech: Bool, category: String?, word: String?) {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        for word in words {
            if let category = bannedWords[word] {
                print("\n=== CSV Kontrolü ===")
                print("Tespit edilen kelime: \(word)")
                print("Kategori: \(category)")
                print("===================\n")
                return (true, category, word)
            }
        }
        
        return (false, nil, nil)
    }
    
    func checkHateSpeech(text: String) async throws -> HateSpeechResponse {
        print("\n=== Nefret Söylemi Kontrolü ===")
        print("Kontrol edilen metin: \(text)")
        
        // Önce CSV tabanlı kontrol
        let localCheck = checkLocalHateSpeech(text)
        if localCheck.containsHateSpeech {
            print("✅ CSV kontrolü: Nefret söylemi tespit edildi")
            
            // Metrics oluştur
            let metrics = HateSpeechResponse.HateSpeechData.Details.Metrics(
                wordCount: text.components(separatedBy: .whitespacesAndNewlines).count,
                averageWordLength: Double(text.count) / Double(text.components(separatedBy: .whitespacesAndNewlines).count),
                punctuationCount: 0,
                capitalizationRatio: 0.0
            )
            
            // Detaylar oluştur
            let details = HateSpeechResponse.HateSpeechData.Details(
                emojiCount: 0,
                textLength: text.count,
                categoryDetails: [localCheck.category ?? "unknown"],
                severityScore: 1.0,
                metrics: metrics
            )
            
            // HateSpeechData oluştur
            let hateSpeechData = HateSpeechResponse.HateSpeechData(
                isHateSpeech: true,
                confidence: 1.0,
                category: localCheck.category ?? "unknown",
                details: details
            )
            
            // HateSpeechResponse oluştur ve dön
            return HateSpeechResponse(
                status: "success",
                data: hateSpeechData,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        }
        
        print("ℹ️ CSV kontrolü: Nefret söylemi tespit edilmedi, API kontrolüne geçiliyor")
        
        // API kontrolü
        guard let url = URL(string: "\(baseURL)/check-hate-speech") else {
            print("❌ Geçersiz URL: \(baseURL)/check-hate-speech")
            throw HateSpeechError.invalidResponse
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
                throw HateSpeechError.connectionError
            }
            
            print("\n=== API Yanıt Detayları ===")
            print("Yanıt Kodu: \(httpResponse.statusCode)")
            print("Yanıt Başlıkları: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Ham Yanıt: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ API hatası: \(httpResponse.statusCode)")
                throw HateSpeechError.serverError(httpResponse.statusCode)
            }
            
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            print("Çözümlenmiş Yanıt: \(apiResponse)")
            print("===================\n")
            
            // APIResponse'u HateSpeechResponse'a dönüştür
            let metrics = HateSpeechResponse.HateSpeechData.Details.Metrics(
                wordCount: apiResponse.data.details.metrics.wordCount,
                averageWordLength: apiResponse.data.details.metrics.averageWordLength,
                punctuationCount: apiResponse.data.details.metrics.punctuationCount,
                capitalizationRatio: apiResponse.data.details.metrics.capitalizationRatio
            )
            
            let details = HateSpeechResponse.HateSpeechData.Details(
                emojiCount: apiResponse.data.details.emojiCount,
                textLength: apiResponse.data.details.textLength,
                categoryDetails: apiResponse.data.details.categoryDetails,
                severityScore: Double(apiResponse.data.details.severityScore),
                metrics: metrics
            )
            
            let hateSpeechData = HateSpeechResponse.HateSpeechData(
                isHateSpeech: apiResponse.data.isHateSpeech,
                confidence: apiResponse.data.confidence,
                category: apiResponse.data.category,
                details: details
            )
            
            let hateSpeechResponse = HateSpeechResponse(
                status: apiResponse.status,
                data: hateSpeechData,
                timestamp: apiResponse.timestamp
            )
            
            print("✅ API kontrolü tamamlandı")
            print("Kategori: \(hateSpeechResponse.data.category)")
            print("Güven Skoru: \(hateSpeechResponse.data.confidence)")
            print("Nefret Söylemi mi?: \(hateSpeechResponse.data.isHateSpeech)")
            print("===================\n")
            
            return hateSpeechResponse
        } catch {
            print("❌ API kontrolünde hata: \(error)")
            throw HateSpeechError.networkError(error)
        }
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
    
    func debouncedCheck(text: String, delay: TimeInterval = 1.0) async throws -> HateSpeechResponse {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        return try await checkHateSpeech(text: text)
    }
}

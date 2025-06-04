import Foundation

public class HateSpeechService {
    static let shared = HateSpeechService()
    private let baseURL = "https://hate-speech-service-main-services.up.railway.app/"
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
            print("❌ Banned words file not found")
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
            print("✅ Banned words loaded: \(bannedWords.count) words")
            // Show some banned words for debug
            print("📖 Some banned words: \(Array(bannedWords.keys.prefix(5)))")
            // Check if "hate" is banned
            if let category = bannedWords["hate"] {
                print("📖 'hate' is banned: \(category)")
            } else {
                print("📖 'hate' is not banned")
            }
            // Check if "fuck" is banned
            if let category = bannedWords["fuck"] {
                print("📖 'fuck' is banned: \(category)")
            } else {
                print("📖 'fuck' is not banned")
            }
        } catch {
            print("❌ Error loading banned words: \(error)")
        }
    }
    
    func checkLocalHateSpeech(_ text: String) -> (containsHateSpeech: Bool, category: String?, word: String?) {
        print("\n💬 LOCAL HATE SPEECH CHECK STARTED: \"\(text)\"")
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        print("💬 Words: \(words)")
        
        for word in words {
            print("💬 Word check: \"\(word)\"")
            if let category = bannedWords[word] {
                print("\n=== CSV Check ===")
                print("Detected word: \(word)")
                print("Category: \(category)")
                print("===================\n")
                return (true, category, word)
            }
        }
        
        print("💬 LOCAL HATE SPEECH CHECK: No banned words found")
        return (false, nil, nil)
    }
    
    func checkHateSpeech(text: String) async throws -> HateSpeechResponse {
        print("\n🔴 HATE SPEECH CHECK STARTED 🔴")
        print("Text being checked: \(text)")
        
        // First CSV-based check
        let localCheck = checkLocalHateSpeech(text)
        if localCheck.containsHateSpeech {
            print("✅ CSV check: Hate speech detected")
            
            // Create metrics
            let metrics = HateSpeechResponse.HateSpeechData.Details.Metrics(
                wordCount: text.components(separatedBy: .whitespacesAndNewlines).count,
                averageWordLength: Double(text.count) / Double(text.components(separatedBy: .whitespacesAndNewlines).count),
                punctuationCount: 0,
                capitalizationRatio: 0.0
            )
            
            // Create details
            let details = HateSpeechResponse.HateSpeechData.Details(
                emojiCount: 0,
                textLength: text.count,
                categoryDetails: [localCheck.category ?? "unknown"],
                severityScore: 1.0,
                metrics: metrics
            )
            
            // Create HateSpeechData
            let hateSpeechData = HateSpeechResponse.HateSpeechData(
                isHateSpeech: true,
                confidence: 1.0,
                category: localCheck.category ?? "unknown",
                details: details
            )
            
            // Create HateSpeechResponse and return
            return HateSpeechResponse(
                status: "success",
                data: hateSpeechData,
                timestamp: ISO8601DateFormatter().string(from: Date())
            )
        }
        
        print("ℹ️ CSV check: Hate speech not detected, proceeding to API check")
        
        // API check
        guard let url = URL(string: "\(baseURL)/api/check-hate-speech") else {
            print("❌ Invalid URL: \(baseURL)/api/check-hate-speech")
            throw HateSpeechError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60
        
        let body = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("\n=== API Request Details ===")
        print("URL: \(url.absoluteString)")
        print("HTTP Method: \(request.httpMethod ?? "")")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        print("Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
        print("===================\n")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                throw HateSpeechError.connectionError
            }
            
            print("\n=== API Response Details ===")
            print("Response Code: \(httpResponse.statusCode)")
            print("Response Headers: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw Response: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ API error: \(httpResponse.statusCode)")
                throw HateSpeechError.serverError(httpResponse.statusCode)
            }
            
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            print("Parsed Response: \(apiResponse)")
            print("===================\n")
            
            // Convert APIResponse to HateSpeechResponse
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
            
            // DÜZELTME: API'nin döndüğü isHateSpeech FALSE olsa bile 
            // category "1" ise nefret söylemi olarak işaretlemek için override ettik
            let isHateSpeech = apiResponse.data.category == "1" ? true : apiResponse.data.isHateSpeech
            
            let hateSpeechData = HateSpeechResponse.HateSpeechData(
                isHateSpeech: isHateSpeech,
                confidence: apiResponse.data.confidence,
                category: apiResponse.data.category,
                details: details
            )
            
            let hateSpeechResponse = HateSpeechResponse(
                status: apiResponse.status,
                data: hateSpeechData,
                timestamp: apiResponse.timestamp
            )
            
            print("✅ API check completed")
            print("Category: \(hateSpeechResponse.data.category)")
            print("Confidence Score: \(hateSpeechResponse.data.confidence)")
            print("Is Hate Speech?: \(hateSpeechResponse.data.isHateSpeech)")
            print("🔴 HATE SPEECH CHECK COMPLETED 🔴\n")
            
            return hateSpeechResponse
        } catch {
            print("❌ API check error: \(error)")
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
            print("Categories request sent: \(url.absoluteString)")
            print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HateSpeechError.connectionError
            }
            
            print("Categories server response code: \(httpResponse.statusCode)")
            print("Categories server response headers: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw categories response: \(responseString)")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("Categories server error: \(httpResponse.statusCode)")
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
            print("Error loading categories: \(error)")
            if let urlError = error as? URLError {
                print("URL Error Details:")
                print("- Error Code: \(urlError.code)")
                print("- Error Description: \(urlError.localizedDescription)")
                print("- Failed URL: \(urlError.failureURLString ?? "Unknown")")
                
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    throw HateSpeechError.connectionError
                case .timedOut:
                    throw HateSpeechError.serverError(408)
                case .cannotConnectToHost:
                    print("Unable to connect to server. Please check the following:")
                    print("1. Is the API server running?")
                    print("2. Is the correct port (8000) being used?")
                    print("3. Is the server address correct?")
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

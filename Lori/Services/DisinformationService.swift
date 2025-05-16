import Foundation
import FirebaseFirestore

enum DisinformationServiceError: Error {
    case invalidResponse
    case apiError(String)
}

class DisinformationService {
    private let db = Firestore.firestore()
    
    private class GaladrielFactCheckService {
        private let apiKey = "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"
        private let apiEndpoint = "https://openrouter.ai/api/v1/chat/completions"
        
        func check(_ content: String) async throws -> String {
            print("Galadriel Fact Check başlatılıyor...")
            
            // Mistral AI's fact check prompt in English
            let factCheckPrompt = """
            Please analyze the following content for factual accuracy:

            CONTENT: \(content)

            First, determine if this is a factual claim that can be verified. If it's an opinion, subjective statement, or too vague, state that it cannot be fact-checked.

            If it can be fact-checked, analyze if it's accurate based on known facts.
            
            IMPORTANT: Keep your analysis VERY BRIEF (max 2-3 sentences). Be direct and concise.
            
            End with ONLY ONE of these verdicts:
            "VERDICT: TRUE" if accurate
            "VERDICT: FALSE" if inaccurate
            "VERDICT: PARTIALLY TRUE" if partly accurate
            "VERDICT: OPINION/UNVERIFIABLE" if it's an opinion or cannot be verified
            """
            
            // API request parameters
            let parameters: [String: Any] = [
                "model": "mistralai/mistral-7b-instruct",
                "messages": [
                    [
                        "role": "system",
                        "content": "You are Galadriel Fact Check, an AI specialized in fact checking. Provide EXTREMELY BRIEF analysis (1-2 sentences only) followed by a clear verdict. Avoid lengthy explanations. Always respond in English."
                    ],
                    [
                        "role": "user",
                        "content": factCheckPrompt
                    ]
                ],
                "temperature": 0.3,
                "max_tokens": 150,
                "route": "fallback"
            ]
            
            // Prepare API request
            guard let url = URL(string: apiEndpoint) else {
                throw DisinformationServiceError.invalidResponse
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("https://lori.app", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("Lori", forHTTPHeaderField: "X-Title")
            request.setValue("OpenRouter/v1", forHTTPHeaderField: "HTTP-Referer")
            request.timeoutInterval = 30
            
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            request.httpBody = jsonData
            
            print("Mistral AI API isteği gönderiliyor...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Mistral AI yanıt durumu: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseString = String(data: data, encoding: .utf8) ?? "Yanıt çözümlenemedi"
                    print("❌ HTTP Hatası \(httpResponse.statusCode): \(responseString)")
                    throw DisinformationServiceError.apiError("HTTP Hatası \(httpResponse.statusCode): \(responseString)")
                }
            }
            
            // Process API response
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = jsonResponse["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let responseText = message["content"] as? String else {
                throw DisinformationServiceError.invalidResponse
            }
            
            print("Mistral AI yanıtı alındı: \(responseText)")
            return responseText
        }
        
        func processResult(_ responseText: String) -> DisinformationResponse {
            let lowercaseResponse = responseText.lowercased()
            
            // Directly use the API response, preserve the original verdict and explanation
            var isVerified = false
            var confidence = 0.5
            
            // Determine verdict and confidence based on response
            if lowercaseResponse.contains("verdict: true") {
                isVerified = true
                confidence = 0.9
            } else if lowercaseResponse.contains("verdict: partially true") {
                isVerified = false
                confidence = 0.7
            } else if lowercaseResponse.contains("verdict: opinion") || lowercaseResponse.contains("verdict: unverifiable") {
                isVerified = false
                confidence = 0.5
            } else if lowercaseResponse.contains("verdict: false") {
                isVerified = false
                confidence = 0.2
            }
            
            // Return response with original text
            return DisinformationResponse(
                isVerified: isVerified,
                sources: nil,
                confidence: confidence,
                explanation: responseText // Pass the original text directly
            )
        }
    }
    
    private let galadrielFactCheckService = GaladrielFactCheckService()
    
    func checkDisinformation(for post: Post) async throws -> DisinformationResponse? {
        if !isNewsOrInformation(post.content) {
            return nil
        }
        
        print("\n=== Galadriel Fact Check Başlatılıyor ===")
        print("İçerik: \(post.content)")
        
        do {
            let factCheckResponse = try await galadrielFactCheckService.check(post.content)
            let result = galadrielFactCheckService.processResult(factCheckResponse)
            
            // Unwrap post.id before using it
            guard let postId = post.id else {
                print("❌ Post ID bulunamadı, doğrulama kaydedilemiyor.")
                return nil
            }
            try await saveDisinformationCheck(postId: postId, response: result)
            return result
        } catch {
            print("Galadriel Fact Check hatası: \(error)")
        }
        
        return nil
    }
    
    private func isNewsOrInformation(_ content: String) -> Bool {
        let newsKeywords = [
            // General News & Information
            "news", "announcement", "statement", "declaration", "announced", "said", "claimed",
            "report", "research", "study", "result", "finding", "discovery", "development", "event",
            "latest", "breaking", "urgent", "important", "critical", "attention", "warning",
            
            // Science & Technology
            "science", "technology", "research", "study", "experiment", "discovery", "invention",
            "scientist", "researcher", "laboratory", "data", "analysis", "theory", "hypothesis",
            "quantum", "genetic", "molecular", "atomic", "particle", "evolution", "climate",
            
            // Health & Medicine
            "health", "medical", "disease", "virus", "bacteria", "vaccine", "treatment",
            "doctor", "hospital", "patient", "symptom", "diagnosis", "prescription", "medicine",
            "pandemic", "epidemic", "infection", "immune", "vaccination", "clinical", "trial",
            
            // Politics & Government
            "government", "president", "minister", "parliament", "election", "vote", "law",
            "policy", "regulation", "decision", "announcement", "statement", "official",
            "administration", "ministry", "department", "agency", "commission", "committee",
            
            // Economy & Business
            "economy", "business", "market", "stock", "investment", "company", "industry",
            "financial", "economic", "trade", "commerce", "bank", "currency", "inflation",
            "recession", "growth", "development", "enterprise", "corporation", "organization",
            
            // Environment & Nature
            "environment", "climate", "nature", "earth", "planet", "global", "warming",
            "pollution", "conservation", "sustainability", "ecosystem", "biodiversity",
            "wildlife", "forest", "ocean", "atmosphere", "weather", "disaster", "natural",
            
            // Education & Academia
            "education", "university", "school", "student", "teacher", "professor", "academic",
            "research", "study", "learning", "teaching", "knowledge", "science", "discipline",
            "degree", "course", "program", "institution", "faculty", "department",
            
            // Türkçe anahtar kelimeler (Türkçe içerikler için)
            "haber", "açıklama", "bildiri", "duyuru", "bildirdi", "söyledi", "iddia",
            "rapor", "araştırma", "çalışma", "sonuç", "bulgu", "keşif", "gelişme", "olay",
            "son dakika", "acil", "önemli", "kritik", "dikkat", "uyarı",
            "bilim", "teknoloji", "deney", "buluş", "bilimsel", "veri", "analiz",
            "sağlık", "tıbbi", "hastalık", "virüs", "aşı", "tedavi", "doktor", "hastane",
            "hükümet", "cumhurbaşkanı", "bakan", "meclis", "seçim", "oy", "kanun", "yasa",
            "ekonomi", "piyasa", "borsa", "yatırım", "şirket", "sektör", "finansal", "banka",
            "çevre", "iklim", "doğa", "dünya", "gezegen", "küresel", "ısınma", "kirlilik",
            "eğitim", "üniversite", "okul", "öğrenci", "öğretmen", "profesör", "akademik"
        ]
        
        let lowercasedContent = content.lowercased()
        return newsKeywords.contains { lowercasedContent.contains($0) }
    }
    
    private func saveDisinformationCheck(postId: String, response: DisinformationResponse) async throws {
        let checkData: [String: Any] = [
            "isVerified": response.isVerified,
            "sources": response.sources ?? [],
            "confidence": response.confidence,
            "explanation": response.explanation,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("posts").document(postId).collection("disinformationChecks").addDocument(data: checkData)
    }
}

// Google Fact Check API response models
struct FactCheckResponse: Codable {
    let claims: [Claim]?
    let nextPageToken: String?
    
    enum CodingKeys: String, CodingKey {
        case claims
        case nextPageToken = "nextPageToken"
    }
}

struct Claim: Codable {
    let text: String?
    let claimReview: [ClaimReview]?
    let claimant: String?
    let claimDate: String?
    
    enum CodingKeys: String, CodingKey {
        case text
        case claimReview
        case claimant
        case claimDate
    }
}

struct ClaimReview: Codable {
    let publisher: Publisher?
    let url: String?
    let textualRating: String?
    let languageCode: String?
    let reviewDate: String?
    
    enum CodingKeys: String, CodingKey {
        case publisher
        case url
        case textualRating
        case languageCode
        case reviewDate
    }
}

struct Publisher: Codable {
    let name: String?
    let site: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case site
    }
}

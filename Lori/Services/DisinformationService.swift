import Foundation
import FirebaseFirestore

enum DisinformationServiceError: Error {
    case invalidResponse
}

class DisinformationService {
    private let db = Firestore.firestore()
    
    private class FactCheckService {
        private let baseURL = "https://factchecktools.googleapis.com/v1alpha1/claims:search"
        private let apiKey = "AIzaSyA0apdZD1C3mnYzNS9po-q16N9Y4JHW2Nw"
        
        func check(_ content: String) async throws -> FactCheckResponse? {
            let query = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "\(baseURL)?query=\(query)&key=\(apiKey)"
            
            print("Fact Check API URL: \(urlString)")
            
            guard let url = URL(string: urlString) else {
                throw DisinformationServiceError.invalidResponse
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Fact Check API Status Code: \(httpResponse.statusCode)")
            }
            
            // API yanıtını string olarak yazdır
            if let responseString = String(data: data, encoding: .utf8) {
                print("Fact Check API Raw Response: \(responseString)")
            }
            
            let decoder = JSONDecoder()
            do {
                let decodedResponse = try decoder.decode(FactCheckResponse.self, from: data)
                print("Fact Check API Decoded Response: \(decodedResponse)")
                return decodedResponse
            } catch {
                print("Fact Check API Decoding Error: \(error)")
                throw error
            }
        }
        
        func processResult(_ response: FactCheckResponse) -> DisinformationResponse? {
            // API'den yanıt gelmediğinde veya boş yanıt geldiğinde
            guard let claims = response.claims, !claims.isEmpty else {
                return DisinformationResponse(
                    isVerified: false,
                    sources: nil,
                    confidence: 0.0,
                    explanation: "🔍 İçerik kontrolü yapılamadı\n\nLori'nin doğrulama sistemi şu anda bu içeriği değerlendiremiyor. Bu durum genellikle içeriğin çok yeni olmasından veya yeterli kaynak bulunamamasından kaynaklanır. Lütfen daha sonra tekrar deneyin."
                )
            }
            
            guard let claim = claims.first else {
                return nil
            }
            
            let rating = claim.claimReview?.first?.textualRating?.lowercased() ?? ""
            let publisher = claim.claimReview?.first?.publisher?.name ?? "Güvenilir Kaynak"
            
            switch rating {
            case "true", "mostly true":
                return DisinformationResponse(
                    isVerified: true,
                    sources: [claim.claimReview?.first?.url ?? ""],
                    confidence: 0.9,
                    explanation: "✅ İçerik Doğrulandı\n\nBu bilgi \(publisher) tarafından doğrulanmıştır. İçerik güvenilir kaynaklarca desteklenmektedir ve doğru bilgi içermektedir."
                )
            case "false", "mostly false", "pants on fire":
                return DisinformationResponse(
                    isVerified: false,
                    sources: [claim.claimReview?.first?.url ?? ""],
                    confidence: 0.9,
                    explanation: "❌ Yanlış Bilgi\n\n\(publisher) tarafından yapılan inceleme sonucunda, bu içerikte yanlış veya yanıltıcı bilgiler tespit edilmiştir. Lütfen güvenilir kaynaklardan bilgi almayı tercih edin."
                )
            case "half true", "mixture":
                return DisinformationResponse(
                    isVerified: false,
                    sources: [claim.claimReview?.first?.url ?? ""],
                    confidence: 0.7,
                    explanation: "⚠️ Kısmen Doğru\n\n\(publisher) tarafından yapılan inceleme sonucunda, bu içerikte bazı doğru bilgiler olsa da, eksik veya yanıltıcı yönler bulunmaktadır. Daha detaylı bilgi için kaynakları incelemenizi öneririz."
                )
            default:
                return DisinformationResponse(
                    isVerified: false,
                    sources: nil,
                    confidence: 0.0,
                    explanation: "🔍 Değerlendirme Yapılamadı\n\nBu içerik henüz Lori'nin doğrulama sisteminde değerlendirilemedi. Bu durum genellikle içeriğin çok yeni olmasından kaynaklanır. Lütfen daha sonra tekrar kontrol edin."
                )
            }
        }
    }
    
    private let factCheckService = FactCheckService()
    
    func checkDisinformation(for post: Post) async throws -> DisinformationResponse? {
        if !isNewsOrInformation(post.content) {
            return nil
        }
        
        print("\n=== Starting Fact Check ===")
        print("Content: \(post.content)")
        
        do {
            if let factCheckResponse = try await factCheckService.check(post.content),
               let result = factCheckService.processResult(factCheckResponse) {
                // Unwrap post.id before using it
                guard let postId = post.id else {
                    print("❌ Post ID is nil, cannot save disinformation check.")
                    return nil // or throw an error
                }
                try await saveDisinformationCheck(postId: postId, response: result)
                return result
            }
        } catch {
            print("Fact Check API error: \(error)")
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
            "degree", "course", "program", "institution", "faculty", "department"
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

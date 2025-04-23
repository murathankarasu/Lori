import Foundation
import FirebaseFirestore

class DisinformationService {
    private let db = Firestore.firestore()
    private let googleService: GoogleFactCheckService
    private let wikipediaService: WikipediaService
    private let newsAPIService: NewsAPIService
    
    private let newsKeywords = [
        // Genel Haber & Bilgi
        "news", "announcement", "statement", "declaration", "announced", "said", "claimed",
        "report", "research", "study", "result", "finding", "discovery", "development", "event",
        "latest", "breaking", "urgent", "important", "critical", "attention", "warning",

        // Hukuk & Yönetim
        "lawsuit", "decision", "law", "regulation", "amendment", "change", "update",
        "government", "minister", "president", "leader", "party", "election", "vote", "referendum",
        "constitution", "legislative", "executive", "judiciary", "court", "prosecutor", "judge",
        "lawyer", "case", "crime", "penalty", "prison", "arrest", "detention", "investigation",
        "indictment", "verdict", "execution",

        // Güvenlik & Kriz
        "danger", "risk", "threat", "attack", "war", "conflict", "crisis", "disaster",
        "earthquake", "flood", "fire", "accident", "death", "injured",

        // Sağlık
        "patient", "pandemic", "virus", "bacteria", "disease", "treatment", "medicine", "vaccine", "health",

        // Ekonomi & İş Dünyası
        "economy", "stock", "dollar", "euro", "inflation", "interest", "credit", "bank",
        "company", "firm", "institution", "organization", "market", "business",

        // Bilim & Astronomi
        "science", "planet", "sun", "moon", "star", "galaxy", "earth", "mars", "jupiter", "saturn",
        "mercury", "venus", "neptune", "uranus", "pluto", "solar system", "astronomy", "space",

        // Coğrafya
        "country", "nation", "state", "city", "capital", "continent", "england", "turkey", "usa",
        "germany", "france", "china", "japan", "russia", "border", "geography", "map",

        // Spor
        "team", "club", "match", "game", "score", "goal", "league", "champion", "player", "athlete",
        "football", "basketball", "tennis", "manchester", "liverpool", "barcelona", "real madrid",
        "lakers", "bulls", "olympics", "sport"
    ]
    
    init() {
        self.googleService = GoogleFactCheckService()
        self.wikipediaService = WikipediaService(newsKeywords: newsKeywords)
        self.newsAPIService = NewsAPIService(newsKeywords: newsKeywords)
    }
    
    private func isNewsOrInformation(_ content: String) -> Bool {
        let lowercasedContent = content.lowercased()
        return newsKeywords.contains { keyword in
            lowercasedContent.contains(keyword)
        }
    }
    
    func checkDisinformation(for post: Post) async throws -> DisinformationResponse {
        if !isNewsOrInformation(post.content) {
            return DisinformationResponse(
                isVerified: true,
                sources: nil,
                confidence: 1.0,
                explanation: "This content does not require verification."
            )
        }
        
        print("\n=== Starting Comprehensive Fact Check ===")
        print("Content: \(post.content)")
        
        var allResults: [VerificationResult] = []
        
        // 1. Google Fact Check API
        do {
            let googleResponse = try await googleService.check(post.content)
            if let result = googleService.processResult(googleResponse) {
                allResults.append(result)
            }
        } catch {
            print("Google Fact Check error: \(error)")
        }
        
        // 2. Wikipedia API
        do {
            let wikiResponse = try await wikipediaService.check(post.content)
            if let result = wikipediaService.processResult(wikiResponse) {
                allResults.append(result)
            }
        } catch {
            print("Wikipedia API error: \(error)")
        }
        
        // 3. News API
        do {
            let newsResponse = try await newsAPIService.check(post.content)
            if let result = newsAPIService.processResult(newsResponse) {
                allResults.append(result)
            }
        } catch {
            print("News API error: \(error)")
        }
        
        let finalResult = evaluateResults(allResults)
        try await saveDisinformationCheck(postId: post.id, response: finalResult)
        return finalResult
    }
    
    private func evaluateResults(_ results: [VerificationResult]) -> DisinformationResponse {
        if results.isEmpty {
            return DisinformationResponse(
                isVerified: false,
                sources: nil,
                confidence: 0.0,
                explanation: "No verification information found from any source."
            )
        }
        
        let sortedResults = results.sorted { first, second in
            let priority: [String: Int] = [
                "Google Fact Check": 1,
                "Wikipedia": 2,
                "News API": 3
            ]
            return (priority[first.source] ?? 0) < (priority[second.source] ?? 0)
        }
        
        let primaryResult = sortedResults.first!
        let allSources = sortedResults.compactMap { $0.sources }.flatMap { $0 }
        
        return DisinformationResponse(
            isVerified: primaryResult.isVerified,
            sources: allSources.isEmpty ? nil : allSources,
            confidence: primaryResult.confidence,
            explanation: primaryResult.explanation
        )
    }
    
    func saveDisinformationCheck(postId: String, response: DisinformationResponse) async throws {
        let checkData: [String: Any] = [
            "isVerified": response.isVerified,
            "sources": response.sources ?? [],
            "confidence": response.confidence,
            "explanation": response.explanation,
            "checkedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("posts").document(postId)
            .collection("disinformationChecks")
            .addDocument(data: checkData)
    }
    
    func getDisinformationCheck(for postId: String) async throws -> DisinformationResponse? {
        let snapshot = try await db.collection("posts")
            .document(postId)
            .collection("disinformationChecks")
            .order(by: "checkedAt", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        do {
            return try document.data(as: DisinformationResponse.self)
        } catch {
            print("Error decoding DisinformationResponse: \(error)")
            return nil
        }
    }
    
    func checkNewPost(_ post: Post) async {
        do {
            _ = try await checkDisinformation(for: post)
        } catch {
            print("Dezenformasyon kontrolü yapılırken hata oluştu: \(error.localizedDescription)")
        }
    }
}

// Özel Hata Enum'ı
enum DisinformationServiceError: Error {
    case rateLimitExceeded
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
}

// Google Fact Check API yanıt modeli
struct FactCheckAPIResponse: Codable {
    let claims: [Claim]?
}

struct Claim: Codable {
    let text: String?
    let claimant: String?
    let claimDate: String?
    let claimReview: [ClaimReview]?
}

struct ClaimReview: Codable {
    let publisher: Publisher?
    let url: String?
    let title: String?
    let reviewDate: String?
    let textualRating: String? // Bu alan doğrulama için kritik
    let languageCode: String?
}

struct Publisher: Codable {
    let name: String?
    let site: String?
}

// Google API Hata modeli
struct GoogleAPIError: Codable {
    let error: GoogleErrorDetail
}

struct GoogleErrorDetail: Codable {
    let code: Int
    let message: String
    let status: String
}

// News API yanıt modeli
struct NewsAPIResponse: Codable {
    let articles: [NewsArticle]
}

struct NewsArticle: Codable {
    let title: String
    let description: String?
    let url: String
    let publishedAt: String
}

// Wikipedia API yanıt modeli
struct WikipediaResponse: Codable {
    let query: WikipediaQuery
}

struct WikipediaQuery: Codable {
    let search: [WikipediaArticle]
}

struct WikipediaArticle: Codable {
    let pageid: Int
    let title: String
    let snippet: String
}

// Doğrulama sonucu modeli
struct VerificationResult: Codable {
    let source: String
    let isVerified: Bool
    let confidence: Double
    let explanation: String
    let sources: [String]?
} 

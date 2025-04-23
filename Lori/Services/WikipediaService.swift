import Foundation

class WikipediaService {
    private let newsKeywords: [String]
    
    init(newsKeywords: [String]) {
        self.newsKeywords = newsKeywords
    }
    
    func check(_ content: String) async throws -> WikipediaResponse {
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "list", value: "search"),
            URLQueryItem(name: "srsearch", value: content),
            URLQueryItem(name: "srlimit", value: "5")
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(WikipediaResponse.self, from: data)
    }
    
    func processResult(_ response: WikipediaResponse) -> VerificationResult? {
        guard !response.query.search.isEmpty else { return nil }
        
        let relevantArticles = response.query.search.filter { article in
            let title = article.title.lowercased()
            return newsKeywords.contains { title.contains($0) }
        }
        
        guard !relevantArticles.isEmpty else { return nil }
        
        let sources = relevantArticles.map { article in
            "https://en.wikipedia.org/?curid=\(article.pageid)"
        }
        
        return VerificationResult(
            source: "Wikipedia",
            isVerified: false,
            confidence: 0.6,
            explanation: "Found \(relevantArticles.count) related Wikipedia articles",
            sources: sources
        )
    }
} 
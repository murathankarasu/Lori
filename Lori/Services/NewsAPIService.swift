import Foundation

class NewsAPIService {
    private let apiKey = "eea10af70f094c12a9963d6c1cff7b87"
    private let newsKeywords: [String]
    
    init(newsKeywords: [String]) {
        self.newsKeywords = newsKeywords
    }
    
    func check(_ content: String) async throws -> [NewsArticle] {
        var components = URLComponents(string: "https://newsapi.org/v2/everything")
        components?.queryItems = [
            URLQueryItem(name: "q", value: content),
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "sortBy", value: "relevancy")
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
        return response.articles
    }
    
    func processResult(_ articles: [NewsArticle]) -> VerificationResult? {
        guard !articles.isEmpty else { return nil }
        
        let relevantArticles = articles.filter { article in
            let content = "\(article.title) \(article.description ?? "")".lowercased()
            return newsKeywords.contains { content.contains($0) }
        }
        
        guard !relevantArticles.isEmpty else { return nil }
        
        return VerificationResult(
            source: "News API",
            isVerified: false,
            confidence: 0.7,
            explanation: "Found \(relevantArticles.count) related news articles",
            sources: relevantArticles.map { $0.url }
        )
    }
} 
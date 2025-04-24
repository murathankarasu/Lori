import Foundation

class GoogleFactCheckService {
    private let apiKey = "*******"
    
    func check(_ content: String) async throws -> FactCheckAPIResponse {
        var components = URLComponents(string: "https://factchecktools.googleapis.com/v1alpha1/claims:search")
        components?.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "query", value: content),
            URLQueryItem(name: "languageCode", value: "en"),
            URLQueryItem(name: "pageSize", value: "5")
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(FactCheckAPIResponse.self, from: data)
    }
    
    func processResult(_ response: FactCheckAPIResponse) -> VerificationResult? {
        guard let firstClaim = response.claims?.first,
              let firstReview = firstClaim.claimReview?.first,
              let textualRating = firstReview.textualRating else {
            return nil
        }
        
        let isVerified = ["true", "mostly true", "accurate"].contains(textualRating.lowercased())
        return VerificationResult(
            source: "Google Fact Check",
            isVerified: isVerified,
            confidence: 0.9,
            explanation: textualRating,
            sources: firstClaim.claimReview?.compactMap { $0.url }
        )
    }
} 

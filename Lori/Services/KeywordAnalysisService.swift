import Foundation
import UIKit

enum KeywordAnalysisError: Error {
    case invalidText
    case noKeywordsFound
}

class KeywordAnalysisService {
    static let shared = KeywordAnalysisService()
    
    // Cache for text analysis results
    private var textCache: [String: [String]] = [:]
    
    // Common English stop words
    private let stopWords: Set<String> = [
        "a", "an", "the", "and", "or", "but", "if", "because", "as", "what",
        "i", "me", "my", "myself", "we", "our", "ours", "ourselves", "you", "your",
        "yours", "yourself", "yourselves", "he", "him", "his", "himself", "she",
        "her", "hers", "herself", "it", "its", "itself", "they", "them", "their",
        "theirs", "themselves", "this", "that", "these", "those", "am", "is", "are",
        "was", "were", "be", "been", "being", "have", "has", "had", "having", "do",
        "does", "did", "doing", "would", "should", "could", "ought", "i'm", "you're",
        "he's", "she's", "it's", "we're", "they're", "i've", "you've", "we've",
        "they've", "i'd", "you'd", "he'd", "she'd", "we'd", "they'd", "i'll",
        "you'll", "he'll", "she'll", "we'll", "they'll", "isn't", "aren't", "wasn't",
        "weren't", "hasn't", "haven't", "hadn't", "doesn't", "don't", "didn't",
        "won't", "wouldn't", "shan't", "shouldn't", "can't", "cannot", "couldn't",
        "mustn't", "let's", "that's", "who's", "what's", "here's", "there's",
        "when's", "where's", "why's", "how's", "um", "uh", "er", "ah", "like",
        "okay", "right", "uhm", "um", "uh", "er", "ah", "like", "okay", "right"
    ]
    
    private init() {}
    
    // Extract keywords from text
    private func extractKeywordsFromText(_ text: String) -> [String] {
        print("\n=== Extracting Keywords from Text ===")
        print("📝 Text to analyze: \(text)")
        
        // Split text into words and clean them
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .filter { $0.count > 3 } // Only words longer than 3 characters
        
        // Remove stop words and count word frequency
        var wordFrequency: [String: Int] = [:]
        for word in words {
            if !stopWords.contains(word) {
                wordFrequency[word, default: 0] += 1
            }
        }
        
        // Sort words by frequency and get top keywords
        let keywords = wordFrequency
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
        
        print("🔍 Extracted keywords: \(keywords.joined(separator: ", "))")
        print("===================\n")
        
        return Array(keywords)
    }
    
    // Analyze text and return keywords
    func analyzeText(_ text: String, operationType: AnalyticsOperationType = .other) async throws -> [String] {
        print("[KeywordAnalysis] Analysis request: \(text), Operation type: \(operationType.rawValue)")
        
        // Check cache first
        if let cachedKeywords = textCache[text] {
            print("[KeywordAnalysis] Using cached keywords")
            return cachedKeywords
        }
        
        // Extract keywords from text
        let keywords = extractKeywordsFromText(text)
        
        // Cache the results
        textCache[text] = keywords
        
        return keywords
    }
}

// Operation type enum (kept for compatibility)
public enum AnalyticsOperationType: String {
    case postCreation = "post_creation"
    case profileImage = "profile_image"
    case other = "other"
} 

import Foundation
import UIKit

/// Anahtar kelime analizi hataları
enum KeywordAnalysisError: Error {
    case invalidText
    case noKeywordsFound
}

/// Metinlerden anahtar kelimeleri çıkaran ve analiz eden servis
/// Bu servis stop words'leri filtreler ve en sık kullanılan kelimeleri tespit eder
/// Sonuçları cache'ler ve performans optimizasyonu sağlar
class KeywordAnalysisService {
    static let shared = KeywordAnalysisService()
    
    // Metin analizi sonuçları için cache
    private var textCache: [String: [String]] = [:]
    
    // Yaygın İngilizce stop words (gereksiz kelimeler)
    // Bu kelimeler analiz sırasında filtrelenir çünkü anlam taşımazlar
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
    
    /// Metinden anahtar kelimeleri çıkarır
    /// Bu fonksiyon metni kelimelere ayırır, stop words'leri filtreler
    /// Kelime frekansını hesaplar ve en sık kullanılan 5 kelimeyi döner
    /// - Parameter text: Analiz edilecek metin
    /// - Returns: [String] - Çıkarılan anahtar kelimeler listesi
    private func extractKeywordsFromText(_ text: String) -> [String] {
        print("\n=== Extracting Keywords from Text ===")
        print("📝 Text to analyze: \(text)")
        
        // Metni kelimelere ayır ve temizle
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .filter { $0.count > 3 } // Sadece 3 karakterden uzun kelimeler
        
        // Stop words'leri kaldır ve kelime frekansını say
        var wordFrequency: [String: Int] = [:]
        for word in words {
            if !stopWords.contains(word) {
                wordFrequency[word, default: 0] += 1
            }
        }
        
        // Kelimeleri frekansa göre sırala ve en üstteki anahtar kelimeleri al
        let keywords = wordFrequency
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
        
        print("🔍 Extracted keywords: \(keywords.joined(separator: ", "))")
        print("===================\n")
        
        return Array(keywords)
    }
    
    /// Metni analiz eder ve anahtar kelimeleri döner
    /// Bu fonksiyon önce cache'i kontrol eder, eğer sonuç cache'de varsa onu döner
    /// Cache'de yoksa yeni analiz yapar ve sonucu cache'ler
    /// - Parameters:
    ///   - text: Analiz edilecek metin
    ///   - operationType: İşlem türü (post oluşturma, profil resmi, diğer)
    /// - Returns: [String] - Analiz edilen anahtar kelimeler
    /// - Throws: KeywordAnalysisError - Geçersiz metin, anahtar kelime bulunamadı
    func analyzeText(_ text: String, operationType: AnalyticsOperationType = .other) async throws -> [String] {
        print("[KeywordAnalysis] Analysis request: \(text), Operation type: \(operationType.rawValue)")
        
        // Önce cache'i kontrol et
        if let cachedKeywords = textCache[text] {
            print("[KeywordAnalysis] Using cached keywords")
            return cachedKeywords
        }
        
        // Metinden anahtar kelimeleri çıkar
        let keywords = extractKeywordsFromText(text)
        
        // Sonuçları cache'le
        textCache[text] = keywords
        
        return keywords
    }
}

/// İşlem türü enum'u (uyumluluk için korundu)
/// Bu enum farklı analiz türlerini belirtmek için kullanılır
public enum AnalyticsOperationType: String {
    case postCreation = "post_creation"  // Post oluşturma
    case profileImage = "profile_image"  // Profil resmi
    case other = "other"                 // Diğer işlemler
} 

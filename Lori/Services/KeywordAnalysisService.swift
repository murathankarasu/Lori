import Foundation
import UIKit

enum KeywordAnalysisError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
}

class KeywordAnalysisService {
    static let shared = KeywordAnalysisService()
    
    private let textAnalysisURL = "https://analytics-service-main-services.up.railway.app/analyze/text"
    private let imageAnalysisURL = "https://analytics-service-main-services.up.railway.app/analyze/image"
    
    private init() {}
    
    // Metin için anahtar kelime analizi
    func analyzeText(_ text: String) async throws -> [String] {
        guard let url = URL(string: textAnalysisURL) else { throw KeywordAnalysisError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("[KeywordAnalysis] API isteği gönderiliyor: \(url)")
        print("[KeywordAnalysis] Gönderilen metin: \(text)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("[KeywordAnalysis] HTTP yanıt kodu: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                throw KeywordAnalysisError.invalidResponse
            }
            if let responseString = String(data: data, encoding: .utf8) {
                print("[KeywordAnalysis] API'den dönen ham yanıt: \(responseString)")
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let labels = json?["labels"] as? [[String: Any]] {
                print("[KeywordAnalysis] labels içeriği: \(labels)")
                let keywords = labels.compactMap { $0["label"] as? String }
                print("[KeywordAnalysis] keywords dizisi: \(keywords)")
                return keywords
            } else {
                print("[KeywordAnalysis] Yanıtta 'labels' alanı bulunamadı veya beklenen formatta değil.")
            }
            return []
        } catch let error as KeywordAnalysisError {
            print("[KeywordAnalysis] KeywordAnalysisError: \(error)")
            throw error
        } catch {
            print("[KeywordAnalysis] Genel hata: \(error)")
            throw KeywordAnalysisError.requestFailed(error)
        }
    }
    
    // Görsel için anahtar kelime analizi
    func analyzeImage(_ image: UIImage) async throws -> [String] {
        guard let url = URL(string: imageAnalysisURL) else { throw KeywordAnalysisError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            data.append(imageData)
            data.append("\r\n".data(using: .utf8)!)
            data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        }
        request.httpBody = data
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: data)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw KeywordAnalysisError.invalidResponse
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let keywords = json?["keywords"] as? [String] ?? []
            return keywords
        } catch let error as KeywordAnalysisError {
            throw error
        } catch {
            throw KeywordAnalysisError.requestFailed(error)
        }
    }
} 
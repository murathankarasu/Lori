import Foundation
import CryptoKit

enum MediaAnalysisError: LocalizedError {
    case networkError(String)
    case invalidURL(String)
    case analysisFailed(statusCode: Int, message: String?)
    case decodingError(String)
    case skippedAnalysis

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Ağ Bağlantı Hatası: \(message)"
        case .invalidURL(let message):
            return "Geçersiz URL: \(message)"
        case .analysisFailed(let statusCode, let message):
            return "Analiz Başarısız (Kod: \(statusCode)): \(message ?? "Detay Yok")"
        case .decodingError(let message):
            return "Yanıt Çözümleme Hatası: \(message)"
        case .skippedAnalysis:
            return "API çağrısı atlandı: Sadece gönderi oluşturma için API çağrısı yapılıyor"
        }
    }
}

class MediaAnalysisService {
    private let imageAnalysisURLString = "https://media-service-main-services.up.railway.app/analyze"
    private let videoAnalysisURLString = "https://media-service-main-services.up.railway.app/analyze_video"
    
    // Add cache for image and video analysis results
    private var imageCache: [String: Bool] = [:]
    private var videoCache: [String: Bool] = [:]

    func analyzeImageData(_ imageData: Data, operationType: AnalyticsOperationType = .other) async throws -> Bool {
        // Generate a hash for the image data to use as cache key
        let imageHash = SHA256.hash(data: imageData).compactMap { String(format: "%02x", $0) }.joined()
        
        print("[MediaAnalysis] Görsel analizi, İşlem türü: \(operationType.rawValue)")
        
        // Only make API calls for post creation
        guard operationType == .postCreation || operationType == .profileImage else {
            print("[MediaAnalysis] Görsel API çağrısı atlanıyor: Sadece gönderi oluşturma ve profil resmi için API çağrısı yapılıyor")
            
            // Check if we have a cached result for this image
            if let cachedResult = imageCache[imageHash] {
                print("[MediaAnalysis] Önbellekten görsel analiz sonucu kullanılıyor")
                return cachedResult
            }
            
            // Default to safe for other operations to avoid API costs
            return true
        }
        
        // Check cache first
        if let cachedResult = imageCache[imageHash] {
            print("[MediaAnalysis] Önbellekten görsel analiz sonucu kullanılıyor")
            return cachedResult
        }
        
        guard let url = URL(string: imageAnalysisURLString) else {
            throw MediaAnalysisError.invalidURL("Resim analiz URL'i geçersiz.")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Multipart body oluştur
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image_file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: body)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MediaAnalysisError.networkError("Geçersiz HTTP yanıtı alındı.")
            }
            
            guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8)
                print("Image analysis failed with status code: \(httpResponse.statusCode), body: \(responseBody ?? "empty")")
                throw MediaAnalysisError.analysisFailed(statusCode: httpResponse.statusCode, message: responseBody)
            }
            
            do {
                let result = try JSONDecoder().decode([String: Double].self, from: data)
                // Olumsuz skorlar için eşik 0.6
                let threshold = 0.6
                let isSafe = (result["gore"] ?? 0) < threshold &&
                             (result["hentai"] ?? 0) < threshold &&
                             (result["porn"] ?? 0) < threshold &&
                             (result["sexy"] ?? 0) < threshold
                
                // Cache the result
                imageCache[imageHash] = isSafe
                
                return isSafe
            } catch {
                throw MediaAnalysisError.decodingError("Resim analiz sonucu çözümlenemedi: \(error.localizedDescription)")
            }
        } catch let error as MediaAnalysisError {
            throw error
        } catch {
            throw MediaAnalysisError.networkError("Resim analizi sırasında ağ hatası: \(error.localizedDescription)")
        }
    }

    func analyzeVideoData(_ videoData: Data, operationType: AnalyticsOperationType = .other) async throws -> Bool {
        // Generate a hash for the video data to use as cache key
        let videoHash = SHA256.hash(data: videoData).compactMap { String(format: "%02x", $0) }.joined()
        
        print("[MediaAnalysis] Video analizi, İşlem türü: \(operationType.rawValue)")
        
        // Only make API calls for post creation
        guard operationType == .postCreation else {
            print("[MediaAnalysis] Video API çağrısı atlanıyor: Sadece gönderi oluşturma için API çağrısı yapılıyor")
            
            // Check if we have a cached result for this video
            if let cachedResult = videoCache[videoHash] {
                print("[MediaAnalysis] Önbellekten video analiz sonucu kullanılıyor")
                return cachedResult
            }
            
            // Default to safe for other operations to avoid API costs
            return true
        }
        
        // Check cache first
        if let cachedResult = videoCache[videoHash] {
            print("[MediaAnalysis] Önbellekten video analiz sonucu kullanılıyor")
            return cachedResult
        }
        
        guard let url = URL(string: videoAnalysisURLString) else {
            throw MediaAnalysisError.invalidURL("Video analiz URL\\'i geçersiz.")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: videoData)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MediaAnalysisError.networkError("Geçersiz HTTP yanıtı alındı.")
            }
            
            guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8)
                print("Video analysis failed with status code: \(httpResponse.statusCode), body: \(responseBody ?? "empty")")
                throw MediaAnalysisError.analysisFailed(statusCode: httpResponse.statusCode, message: responseBody)
            }
            
            do {
                let result = try JSONDecoder().decode([String: Bool].self, from: data)
                let isSafe = result["safe"] ?? false
                
                // Cache the result
                videoCache[videoHash] = isSafe
                
                return isSafe
            } catch {
                throw MediaAnalysisError.decodingError("Video analiz sonucu çözümlenemedi: \(error.localizedDescription)")
            }
        } catch let error as MediaAnalysisError {
            throw error
        } catch {
            throw MediaAnalysisError.networkError("Video analizi sırasında ağ hatası: \(error.localizedDescription)")
        }
    }
} 
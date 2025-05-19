import Foundation

enum MediaAnalysisError: LocalizedError {
    case networkError(String)
    case invalidURL(String)
    case analysisFailed(statusCode: Int, message: String?)
    case decodingError(String)

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
        }
    }
}

class MediaAnalysisService {
    private let imageAnalysisURLString = "https://media-service-main-services.up.railway.app/analyze"
    private let videoAnalysisURLString = "https://media-service-main-services.up.railway.app/analyze_video"

    func analyzeImageData(_ imageData: Data) async throws -> Bool {
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

    func analyzeVideoData(_ videoData: Data) async throws -> Bool {
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
                return result["safe"] ?? false
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
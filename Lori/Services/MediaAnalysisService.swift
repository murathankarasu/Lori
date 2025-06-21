import Foundation
import CryptoKit
import os.log
import UIKit

// Sightengine API Response Models
struct SightengineResponse: Codable {
    let status: String
    let request: SightengineRequest?
    let nudity: SightengineNudity?
    let violence: SightengineViolence?
    let weapon: SightengineWeapon?
    let gore: SightengineGore?
    let faces: [SightengingFace]?
    let error: SightengineError?
}

struct SightengineRequest: Codable {
    let id: String?
    let timestamp: Double?
    let operations: Int?
}

struct SightengineNudity: Codable {
    let sexual_activity: Double?
    let sexual_display: Double?
    let erotica: Double?
    let suggestive: Double?
    let none: Double?
}

struct SightengineViolence: Codable {
    let prob: Double?
}

struct SightengineWeapon: Codable {
    let prob: Double?
}

struct SightengineGore: Codable {
    let prob: Double?
}

struct SightengingFace: Codable {
    let x1: Int?
    let y1: Int?
    let x2: Int?
    let y2: Int?
}

struct SightengineError: Codable {
    let type: String?
    let code: Int?
    let message: String?
}

/// Medya analizi hataları
enum MediaAnalysisError: LocalizedError {
    case networkError(String)
    case invalidURL(String)
    case analysisFailed(statusCode: Int, message: String?)
    case decodingError(String)
    case skippedAnalysis
    case apiUnavailable(String)
    case imageProcessingError(String)
    case authenticationError(String)
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .invalidURL(let message):
            return "Invalid URL: \(message)"
        case .analysisFailed(let statusCode, let message):
            return "Analysis Failed (Code: \(statusCode)): \(message ?? "No details")"
        case .decodingError(let message):
            return "Response Decoding Error: \(message)"
        case .skippedAnalysis:
            return "API call skipped: Only called for post creation."
        case .apiUnavailable(let message):
            return "API Unavailable: \(message)"
        case .imageProcessingError(let message):
            return "Image Processing Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .invalidCredentials:
            return "Invalid API Keys"
        }
    }
}

/// Medya içerik analizi servisi
/// Bu servis Sightengine API kullanarak görsellerde uygunsuz içerik tespiti yapar
/// NSFW, şiddet, silah, kan gibi içerikleri tespit eder
/// Retry mekanizması ve cache sistemi ile güvenilirlik sağlar
class MediaAnalysisService {
    // Sightengine API Konfigürasyonu
    private let sightengineAPIURL = "https://api.sightengine.com/1.0/check.json"
    private let apiUser = "1381822354" // Gerçek API kullanıcı adınızla değiştirin
    private let apiSecret = "4QqdF2a8TSyJMdE2hGDAd3CCpTcHsPHH" // Gerçek API şifrenizle değiştirin
    
    private let logger = Logger(subsystem: "com.lorien.app", category: "MediaAnalysis")
    
    // Konfigürasyon sabitleri
    private let maxImageSizeBytes: Int = 8_000_000 // Sightengine için 8MB maksimum
    private let compressionQuality: CGFloat = 0.9
    private let maxDimension: CGFloat = 2048 // Daha iyi doğruluk için yüksek çözünürlük
    private let baseTimeoutInterval: TimeInterval = 30 // Sightengine çok daha hızlı
    private let maxTimeoutInterval: TimeInterval = 60
    
    // İçerik moderasyon eşikleri
    private let nsfwThreshold: Double = 0.5
    private let violenceThreshold: Double = 0.5
    private let weaponThreshold: Double = 0.5
    private let goreThreshold: Double = 0.3 // Kan için daha düşük eşik (daha katı)
    
    // Görsel analizi sonuçları için cache
    private var imageCache: [String: Bool] = [:]
    
    // API durumunu kontrol etmek için
    private var lastApiCheck: Date?
    private var isApiAvailable: Bool = true
    private var retryCount: Int = 0
    private let maxRetries: Int = 3
    private let retryDelay: TimeInterval = 2.0

    /// Belirli HTTP durum kodları için retry yapılıp yapılmayacağını belirler
    /// 5xx hataları ve belirli 4xx hataları için retry yapar
    /// - Parameter statusCode: HTTP durum kodu
    /// - Returns: Bool - Retry yapılacak mı
    private func shouldRetry(statusCode: Int) -> Bool {
        // 5xx hataları ve geçici olabilecek belirli 4xx hataları için retry
        return (statusCode >= 500 && statusCode < 600) || 
               (statusCode == 429) || // Too Many Requests
               (statusCode == 408) || // Request Timeout
               (statusCode == 502) || // Bad Gateway
               (statusCode == 503) || // Service Unavailable
               (statusCode == 504)    // Gateway Timeout
    }

    /// Ağ hataları için retry yapılıp yapılmayacağını belirler
    /// Timeout ve ağ bağlantı sorunları için retry yapar
    /// - Parameter error: Ağ hatası
    /// - Returns: Bool - Retry yapılacak mı
    private func shouldRetryOnNetworkError(_ error: Error) -> Bool {
        // Timeout ve ağ bağlantı sorunları için retry
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && (
            nsError.code == NSURLErrorTimedOut ||
            nsError.code == NSURLErrorNetworkConnectionLost ||
            nsError.code == NSURLErrorNotConnectedToInternet ||
            nsError.code == NSURLErrorCannotConnectToHost
        )
    }

    /// Retry gecikmesini hesaplar
    /// Exponential backoff ile jitter ekler
    /// - Returns: TimeInterval - Gecikme süresi
    private func getRetryDelay() -> TimeInterval {
        // Exponential backoff ile jitter
        let baseDelay = retryDelay * pow(2.0, Double(retryCount))
        let jitter = Double.random(in: 0...0.3) * baseDelay
        return min(baseDelay + jitter, 15.0) // 15 saniye ile sınırla
    }

    /// Retry durumunu sıfırlar
    /// API'nin tekrar kullanılabilir olduğunu işaretler
    private func resetRetryState() {
        retryCount = 0
        isApiAvailable = true
        lastApiCheck = nil
    }

    /// Görseli sıkıştırır ve yeniden boyutlandırır
    /// Bu fonksiyon API'ye gönderilecek görseli optimize eder
    /// Maksimum boyut sınırlarını aşmamak için sıkıştırma yapar
    /// - Parameter imageData: İşlenecek görsel verisi
    /// - Returns: Data - İşlenmiş görsel verisi
    /// - Throws: MediaAnalysisError - Görsel işleme hatası
    private func compressAndResizeImage(_ imageData: Data) throws -> Data {
        guard let image = UIImage(data: imageData) else {
            throw MediaAnalysisError.imageProcessingError("Unsupported image format")
        }
        
        let originalSize = image.size
        logger.info("Original image size: \(originalSize.width)x\(originalSize.height), Data size: \(imageData.count) bytes")
        
        // Gerekirse yeni boyutu hesapla
        var newSize = originalSize
        if originalSize.width > maxDimension || originalSize.height > maxDimension {
            let ratio = min(maxDimension / originalSize.width, maxDimension / originalSize.height)
            newSize = CGSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
            logger.info("Image will be resized: \(newSize.width)x\(newSize.height)")
        }
        
        // Gerekirse yeniden boyutlandır
        var processedImage = image
        if newSize != originalSize {
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            processedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }
        
        // Sıkıştır
        var quality = compressionQuality
        var compressedData = processedImage.jpegData(compressionQuality: quality)
        
        // Hala çok büyükse kaliteyi kademeli olarak azalt
        while let data = compressedData, data.count > maxImageSizeBytes && quality > 0.2 {
            quality -= 0.1
            compressedData = processedImage.jpegData(compressionQuality: quality)
            logger.info("Compression quality reduced: \(quality), New size: \(data.count) bytes")
        }
        
        guard let finalData = compressedData else {
            throw MediaAnalysisError.imageProcessingError("Image could not be compressed")
        }
        
        logger.info("Processed image size: \(finalData.count) bytes, Quality: \(quality)")
        return finalData
    }

    /// Görsel boyutuna göre timeout hesaplar
    /// Büyük görseller için daha uzun timeout süresi verir
    /// - Parameter dataSize: Görsel veri boyutu
    /// - Returns: TimeInterval - Timeout süresi
    private func calculateTimeoutForImageSize(_ dataSize: Int) -> TimeInterval {
        // Görsel boyutuna göre dinamik timeout (Sightengine çok daha hızlı)
        let sizeMB = Double(dataSize) / 1_000_000.0
        let dynamicTimeout = baseTimeoutInterval + (sizeMB * 5.0) // MB başına 5 saniye ekle
        return min(dynamicTimeout, maxTimeoutInterval)
    }

    /// Sightengine API yanıtından güvenlik değerlendirmesi yapar
    /// NSFW, şiddet, silah, kan içeriklerini kontrol eder
    /// Belirlenen eşik değerlerine göre güvenli/güvensiz kararı verir
    /// - Parameter response: Sightengine API yanıtı
    /// - Returns: Bool - Görsel güvenli mi (true: güvenli, false: güvensiz)
    private func evaluateSafetyFromSightengineResponse(_ response: SightengineResponse) -> Bool {
        logger.info("Sightengine response being evaluated: \(String(describing: response))")
        
        // API hatalarını kontrol et
        if let error = response.error {
            logger.error("Sightengine API error: \(error.message ?? "Unknown error")")
            return true // API hatalarında varsayılan olarak güvenli
        }
        
        // NSFW içeriği kontrol et
        if let nudity = response.nudity {
            let sexualActivity: Double = nudity.sexual_activity ?? 0.0
            let sexualDisplay: Double = nudity.sexual_display ?? 0.0
            let erotica: Double = nudity.erotica ?? 0.0
            let suggestive: Double = nudity.suggestive ?? 0.0
            
            if sexualActivity > nsfwThreshold || 
               sexualDisplay > nsfwThreshold || 
               erotica > nsfwThreshold ||
               suggestive > (nsfwThreshold + 0.2) { // Suggestive için daha yüksek eşik
                logger.info("NSFW content detected - Sexual Activity: \(sexualActivity), Sexual Display: \(sexualDisplay), Erotica: \(erotica), Suggestive: \(suggestive)")
                return false
            }
        }
        
        // Şiddet kontrolü
        if let violence = response.violence, let violenceProb: Double = violence.prob {
            if violenceProb > violenceThreshold {
                logger.info("Violence content detected - Probability: \(violenceProb)")
                return false
            }
        }
        
        // Silah kontrolü
        if let weapon = response.weapon, let weaponProb: Double = weapon.prob {
            if weaponProb > weaponThreshold {
                logger.info("Weapon content detected - Probability: \(weaponProb)")
                return false
            }
        }
        
        // Kan kontrolü
        if let gore = response.gore, let goreProb: Double = gore.prob {
            if goreProb > goreThreshold {
                logger.info("Gore content detected - Probability: \(goreProb)")
                return false
            }
        }
        
        logger.info("Image evaluated as safe")
        return true
    }

    /// Görsel verisini analiz eder
    /// Bu fonksiyon Sightengine API kullanarak görselde uygunsuz içerik tespiti yapar
    /// Sadece post oluşturma ve profil resmi işlemleri için API çağrısı yapar
    /// Diğer işlemler için cache'den sonuç döner veya güvenli varsayar
    /// - Parameters:
    ///   - imageData: Analiz edilecek görsel verisi
    ///   - operationType: İşlem türü (post oluşturma, profil resmi, diğer)
    /// - Returns: Bool - Görsel güvenli mi (true: güvenli, false: güvensiz)
    /// - Throws: MediaAnalysisError - Ağ hatası, API hatası, kimlik doğrulama hatası
    func analyzeImageData(_ imageData: Data, operationType: AnalyticsOperationType = .other) async throws -> Bool {
        // API kimlik bilgilerini doğrula
        guard apiUser != "YOUR_SIGHTENGINE_API_USER" && apiSecret != "YOUR_SIGHTENGINE_API_SECRET" else {
            logger.error("Sightengine API credentials not set")
            throw MediaAnalysisError.invalidCredentials
        }
        
        // Görsel verisi için hash oluştur (cache anahtarı olarak kullan)
        let imageHash: String = SHA256.hash(data: imageData).compactMap { String(format: "%02x", $0) }.joined()
        
        logger.info("Starting Sightengine image analysis, Operation type: \(operationType.rawValue), Image size: \(imageData.count) bytes")
        
        // API kullanılabilirliğini kontrol et
        if !isApiAvailable {
            // Son kontrol 5 dakikadan eskiyse tekrar dene
            if let lastCheck = lastApiCheck, Date().timeIntervalSince(lastCheck) > 300 {
                resetRetryState()
                logger.info("Sightengine API being checked again")
            } else {
                logger.warning("Sightengine API currently unavailable, returning cached result")
                return true // API kullanılamıyorsa varsayılan olarak güvenli
            }
        }
        
        // Sadece post oluşturma ve profil resimleri için API çağrısı yap
        guard operationType == .postCreation || operationType == .profileImage else {
            logger.info("Sightengine API call skipped: Only called for post creation and profile image")
            
            // Bu görsel için cache'de sonuç var mı kontrol et
            if let cachedResult = imageCache[imageHash] {
                logger.info("Using cached image analysis result")
                return cachedResult
            }
            
            // Diğer işlemler için API maliyetini önlemek amacıyla güvenli varsay
            return true
        }
        
        // Önce cache'i kontrol et
        if let cachedResult = imageCache[imageHash] {
            logger.info("Using cached Sightengine analysis result")
            return cachedResult
        }
        
        guard let url = URL(string: self.sightengineAPIURL) else {
            logger.error("Sightengine API URL invalid: \(self.sightengineAPIURL)")
            throw MediaAnalysisError.invalidURL("Sightengine API URL invalid.")
        }
        
        // Görseli işle ve sıkıştır
        let processedImageData: Data
        do {
            processedImageData = try compressAndResizeImage(imageData)
        } catch {
            logger.error("Image processing error: \(error.localizedDescription)")
            // Görsel işleme başarısız olursa orijinal veriyle dene
            processedImageData = imageData
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Görsel boyutuna göre dinamik timeout
        let timeoutInterval = calculateTimeoutForImageSize(processedImageData.count)
        request.timeoutInterval = timeoutInterval
        logger.info("Sightengine API timeout set: \(timeoutInterval) seconds")

        // Sightengine API için multipart form data oluştur
        var body = Data()
        
        // API kimlik bilgilerini ekle
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"api_user\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(apiUser)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"api_secret\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(apiSecret)\r\n".data(using: .utf8)!)
        
        // Kontrol edilecek modelleri ekle
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"models\"\r\n\r\n".data(using: .utf8)!)
        body.append("nudity-2.0,violence,weapon,gore\r\n".data(using: .utf8)!)
        
        // Görsel dosyasını ekle
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"media\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(processedImageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        do {
            logger.info("Sending Sightengine API request: \(url.absoluteString), Processed image size: \(processedImageData.count) bytes")
            let (data, response) = try await URLSession.shared.upload(for: request, from: body)
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid HTTP response received")
                throw MediaAnalysisError.networkError("Invalid HTTP response received.")
            }
            
            logger.info("Sightengine API response received, status code: \(httpResponse.statusCode)")
            
            if shouldRetry(statusCode: httpResponse.statusCode) && self.retryCount < self.maxRetries {
                self.retryCount += 1
                let delay = getRetryDelay()
                logger.info("Retrying due to server error (Attempt \(self.retryCount)/\(self.maxRetries)), Waiting \(delay) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await analyzeImageData(imageData, operationType: operationType)
            }
            
            guard httpResponse.statusCode == 200 else {
                let responseBody = String(data: data, encoding: .utf8)
                logger.error("Sightengine analysis failed, status code: \(httpResponse.statusCode), response: \(responseBody ?? "empty")")
                
                // Kimlik doğrulama hatalarını kontrol et
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw MediaAnalysisError.authenticationError("Sightengine API authentication error")
                }
                
                // Sunucu hatalarında API'yi kullanılamaz olarak işaretle
                if httpResponse.statusCode >= 500 {
                    isApiAvailable = false
                    lastApiCheck = Date()
                    logger.warning("Sightengine API marked as temporarily unavailable due to server error")
                    
                    // Sunucu hatalarında kullanıcı deneyimini engellememek için güvenli sonuç döndür
                    logger.info("Returning safe result due to server error")
                    return true
                }
                
                throw MediaAnalysisError.analysisFailed(statusCode: httpResponse.statusCode, message: responseBody)
            }
            
            // Başarıda retry durumunu sıfırla
            resetRetryState()
            
            do {
                let sightengineResult = try JSONDecoder().decode(SightengineResponse.self, from: data)
                logger.info("Sightengine API response successfully decoded")
                
                let isSafe = evaluateSafetyFromSightengineResponse(sightengineResult)
                
                logger.info("Sightengine image analysis result: \(isSafe ? "Safe" : "Unsafe")")
                
                // Sonucu cache'le
                imageCache[imageHash] = isSafe
                
                return isSafe
            } catch {
                logger.error("Sightengine response could not be decoded: \(error.localizedDescription)")
                throw MediaAnalysisError.decodingError("Sightengine response could not be decoded: \(error.localizedDescription)")
            }
        } catch let error as MediaAnalysisError {
            logger.error("Sightengine MediaAnalysis error: \(error.localizedDescription ?? "Unknown error")")
            throw error
        } catch {
            logger.error("Sightengine analysis encountered network error: \(error.localizedDescription)")
            
            // Ağ hatalarında retry (timeout dahil)
            if shouldRetryOnNetworkError(error) && self.retryCount < self.maxRetries {
                self.retryCount += 1
                let delay = getRetryDelay()
                logger.info("Retrying due to network error (Attempt \(self.retryCount)/\(self.maxRetries)), Waiting \(delay) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await analyzeImageData(imageData, operationType: operationType)
            }
            
            // Tüm denemeler başarısız olursa API'yi kullanılamaz olarak işaretle ve güvenli sonuç döndür
            if self.retryCount >= self.maxRetries {
                isApiAvailable = false
                lastApiCheck = Date()
                logger.warning("All attempts failed, Sightengine API marked as temporarily unavailable. Returning safe result.")
                return true
            }
            
            throw MediaAnalysisError.networkError("Sightengine analysis encountered network error: \(error.localizedDescription)")
        }
    }
} 

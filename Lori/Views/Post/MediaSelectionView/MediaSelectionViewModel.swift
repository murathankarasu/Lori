import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseAuth

// Medya Analiz Sonucu için model
struct MediaAnalysisResult {
    let isSafe: Bool
    let details: [String: Double]?
    let errorMessage: String?
    
    // Eğer detaylar varsa, en yüksek olumsuz kategorileri döndürür
    var highestNegativeCategories: [(String, Double)] {
        guard let details = details else { return [] }
        
        // 0.3'ten büyük değerleri filtrele ve azalan sırayla sırala
        return details.filter { $0.value > 0.3 }
            .sorted { $0.value > $1.value }
    }
    
    // Basit bir mesaj oluştur
    var resultMessage: String {
        if let error = errorMessage {
            return "Hata: \(error)"
        }
        
        if isSafe {
            return "Görsel içeriği uygun"
        } else {
            let categories = highestNegativeCategories.map { "\($0.0): %\(Int($0.1 * 100))" }.joined(separator: ", ")
            return "Görsel içeriği politikalara aykırı\n\(categories.isEmpty ? "" : "Tespit edilen kategoriler: \(categories)")"
        }
    }
    
    // Sonuç tipini belirleyen getter
    var resultType: ResultType {
        if errorMessage != nil {
            return .error
        }
        return isSafe ? .success : .violation
    }
    
    enum ResultType {
        case success
        case violation
        case error
        
        // Her sonuç tipine özel simge ve renk
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .violation: return "exclamationmark.triangle.fill"
            case .error: return "xmark.octagon.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .violation: return .orange
            case .error: return .red
            }
        }
    }
}

@MainActor
class MediaSelectionViewModel: ObservableObject {
    // Seçilen görsel
    @Published var selectedImage: UIImage?
    @Published var isAnalyzing: Bool = false
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published var isApproved: Bool = false
    
    // Gelişmiş geri bildirim için eklemeler
    @Published var analysisResult: MediaAnalysisResult?
    @Published var showAnalysisDetails: Bool = false
    @Published var showFeedbackAnimation: Bool = false
    @Published var feedbackMessage: String = ""
    @Published var feedbackType: MediaAnalysisResult.ResultType = .success
    
    // Firebase Storage için eklemeler
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0.0
    @Published var imageUrl: String? = nil
    @Published var imageStoragePath: String? = nil
    
    // Özel Storage bucket URL'i
    private let storage = Storage.storage()
    
    // Analiz servisi
    private let mediaAnalysisService = MediaAnalysisService()
    
    // Görsel analizi yap - geliştirilmiş versiyon
    func analyzeImage(_ image: UIImage) async -> MediaAnalysisResult {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            // Resim verisini JPEG olarak sıkıştır
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                let result = MediaAnalysisResult(
                    isSafe: false,
                    details: nil,
                    errorMessage: "Görsel işlenemedi"
                )
                return result
            }
            
            // MediaAnalysisService ile görsel içeriğini analiz et
            do {
                let isSafe = try await mediaAnalysisService.analyzeImageData(imageData)
                
                // Burada gerçek MediaAnalysisService'den dönen detay bilgileri alınabilir
                // Şu anki implementasyonda sadece boolean dönüyor, bunu geliştirmek için
                // MediaAnalysisService'i değiştirmek gerekebilir
                
                // Şimdilik örnek bir detay yapısı oluşturalım
                var details: [String: Double]? = nil
                
                if !isSafe {
                    // Gerçek serviste bu veriler döner, şimdilik test için
                    details = [
                        "gore": 0.25,
                        "hentai": 0.15,
                        "porn": 0.65,
                        "sexy": 0.35
                    ]
                }
                
                let result = MediaAnalysisResult(
                    isSafe: isSafe,
                    details: details,
                    errorMessage: nil
                )
                
                return result
                
            } catch let error as MediaAnalysisError {
                let result = MediaAnalysisResult(
                    isSafe: false,
                    details: nil,
                    errorMessage: error.localizedDescription
                )
                return result
            }
            
        } catch {
            let result = MediaAnalysisResult(
                isSafe: false,
                details: nil,
                errorMessage: "Görsel analizi sırasında hata oluştu: \(error.localizedDescription)"
            )
            return result
        }
    }
    
    // Seçilen görseli analiz et, onayla ve yükle
    func processSelectedImage() async {
        guard let image = selectedImage else { return }
        
        // Analiz yap ve sonucu sakla
        let result = await analyzeImage(image)
        analysisResult = result
        
        // Sonucu işle
        isApproved = result.isSafe
        errorMessage = result.isSafe ? "" : result.resultMessage
        showError = !result.isSafe
        
        // Geri bildirim animasyonu göster
        showFeedback(for: result)
        
        // Eğer analiz başarılıysa geçici storage'a yükle
        if result.isSafe {
            await uploadImageToTempStorage(image)
        }
    }
    
    // Firebase Storage'a geçici görsel yükleme
    func uploadImageToTempStorage(_ image: UIImage) async {
        guard let currentUser = Auth.auth().currentUser else {
            errorMessage = "Oturum açmanız gerekiyor"
            showError = true
            return
        }
        
        isUploading = true
        uploadProgress = 0.0
        
        do {
            // Görseli standart boyuta getir (4:3 oranı)
            let standardizedImage = resizeImageToStandardSize(image)
            
            // Resim verisini JPEG olarak sıkıştır
            guard let imageData = standardizedImage.jpegData(compressionQuality: 0.7) else {
                errorMessage = "Görsel işlenemedi"
                showError = true
                isUploading = false
                return
            }
            
            // Tamamen benzersiz bir dosya adı oluştur
            let imageId = UUID().uuidString
            let fileName = "image-\(Int(Date().timeIntervalSince1970))-\(imageId).jpg"
            
            // Doğrudan posts klasörüne yükle (temp-posts KULLANMIYORUZ)
            let imagePath = "posts/\(currentUser.uid)/\(fileName)"
            
            // Storage referansı oluştur
            let storageRef = storage.reference().child(imagePath)
            
            // Metadata ayarla
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            // Dosyanın var olup olmadığını kontrol et
            var fileExists = false
            do {
                _ = try await storageRef.getMetadata()
                fileExists = true
                print("Dosya zaten mevcut: \(imagePath)")
            } catch {
                fileExists = false
                print("Dosya mevcut değil, yükleme yapılacak: \(imagePath)")
            }
            
            // Eğer dosya zaten varsa, tekrar yükleme yapmaya gerek yok
            // Ancak dosya yoksa, yeni bir yükleme işlemi başlat
            if !fileExists {
                // Yükleme işlemi
                let uploadTask = storageRef.putData(imageData, metadata: metadata)
                
                // İlerleme takibi
                _ = uploadTask.observe(.progress) { [weak self] snapshot in
                    guard let self = self else { return }
                    let progress = Double(snapshot.progress?.completedUnitCount ?? 0) / 
                                Double(snapshot.progress?.totalUnitCount ?? 1)
                    Task { @MainActor in
                        self.uploadProgress = progress
                    }
                }
                
                // Yükleme işlemini bekle
                _ = try await uploadTask.snapshot
                print("Dosya başarıyla yüklendi: \(imagePath)")
            }
            
            // Firebase'in URL'yi güncellemesi için kısa bir gecikme ekle
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 saniye bekle
            
            // URL'yi al (dosya var olsun veya olmasın)
            var downloadURL: URL
            do {
                // URL'yi almaya çalış
                downloadURL = try await storageRef.downloadURL()
                print("Dosya URL'si alındı: \(downloadURL.absoluteString)")
            } catch {
                print("Dosya URL'si alınamadı, manuel oluşturuluyor: \(error)")
                // URL'yi manuel olarak oluştur
                let encodedPath = imagePath.replacingOccurrences(of: "/", with: "%2F")
                
                // Manuel URL'yi Firebase Storage'ın beklediği formatta oluştur
                let firebaseStorageUrl = "https://firebasestorage.googleapis.com/v0/b/lorien-app-tr.firebasestorage.app/o/\(encodedPath)?alt=media"
                let manualURL = URL(string: firebaseStorageUrl)!
                downloadURL = manualURL
                print("Manuel oluşturulan URL: \(downloadURL.absoluteString)")
                
                // URL çalışabilir olana kadar ek süre bekle
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 saniye daha bekle
            }
            
            // URL'yi ve storage yolunu sakla
            await MainActor.run {
                self.imageUrl = downloadURL.absoluteString
                self.imageStoragePath = imagePath
            }
            
            print("Görsel başarıyla yüklendi: \(imagePath)")
            
        } catch {
            await MainActor.run {
                // Hata mesajını daha açıklayıcı hale getir
                let errorString = error.localizedDescription
                
                if errorString.contains("does not exist") {
                    self.errorMessage = "Görsel yüklenirken dosya erişim hatası oluştu. Lütfen farklı bir görsel deneyin."
                } else if errorString.contains("permission") || errorString.contains("unauthorized") {
                    self.errorMessage = "Yetkilendirme hatası. Lütfen tekrar giriş yapın ve tekrar deneyin."
                } else if errorString.contains("network") || errorString.contains("connection") {
                    self.errorMessage = "Ağ hatası. İnternet bağlantınızı kontrol edin ve tekrar deneyin."
                } else {
                    self.errorMessage = "Görsel yükleme sırasında bir sorun oluştu. Lütfen tekrar deneyin."
                }
                
                self.showError = true
            }
            print("Hata detayı: \(error)")
        }
        
        await MainActor.run {
            self.isUploading = false
        }
    }
    
    // Geri bildirim göster
    private func showFeedback(for result: MediaAnalysisResult) {
        feedbackType = result.resultType
        feedbackMessage = result.resultMessage
        
        // Animasyonu göster
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showFeedbackAnimation = true
        }
        
        // Sonuç olumluysa daha kısa süre göster (akışı hızlandırmak için)
        let displayDuration = result.isSafe ? 1.5 : 3.0
        
        // Belirtilen süre sonra kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showFeedbackAnimation = false
            }
        }
    }
    
    // Temizleme işlemi
    func reset() {
        selectedImage = nil
        isAnalyzing = false
        errorMessage = ""
        showError = false
        isApproved = false
        analysisResult = nil
        showAnalysisDetails = false
        feedbackMessage = ""
        showFeedbackAnimation = false
        isUploading = false
        uploadProgress = 0.0
        // imageUrl ve imageStoragePath sıfırlanmıyor çünkü CreatePostView'a geçiriliyor
    }
    
    // Görsel veya path silme
    func deleteUploadedImage() async {
        guard let path = imageStoragePath else { 
            print("Silinecek dosya yolu bulunamadı")
            return 
        }
        
        print("Dosya silme işlemi başlatılıyor: \(path)")
        
        do {
            let storageRef = storage.reference().child(path)
            
            // Silme işlemini gerçekleştir
            try await storageRef.delete()
            print("Dosya başarıyla silindi: \(path)")
            
            // Başarıyla silindikten sonra referansları temizle
            await MainActor.run {
                self.imageStoragePath = nil
                self.imageUrl = nil
            }
        } catch let error as NSError {
            if error.domain == StorageErrorDomain && error.code == StorageErrorCode.objectNotFound.rawValue {
                print("Dosya bulunamadı, zaten silinmiş olabilir: \(path)")
                // Referansları yine de temizle
                await MainActor.run {
                    self.imageStoragePath = nil
                    self.imageUrl = nil
                }
            } else {
                print("Dosya silme hatası: \(error.localizedDescription)")
            }
        } catch {
            print("Beklenmeyen hata: \(error.localizedDescription)")
        }
    }
    
    // Görseli standart boyuta getirme fonksiyonu (4:3 oranında, 400x300 piksel)
    private func resizeImageToStandardSize(_ image: UIImage) -> UIImage {
        let targetSize = CGSize(width: 400, height: 350)
        
        // Kaynak boyutları
        let sourceWidth = image.size.width
        let sourceHeight = image.size.height
        
        // Hedef en boy oranını hesapla (4:3)
        let targetRatio = targetSize.width / targetSize.height
        let sourceRatio = sourceWidth / sourceHeight
        
        // Kırpma için gereken boyutları hesapla
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if sourceRatio > targetRatio {
            // Görsel daha geniş, yüksekliği sınırla
            newHeight = sourceHeight
            newWidth = sourceHeight * targetRatio
        } else {
            // Görsel daha uzun, genişliği sınırla
            newWidth = sourceWidth
            newHeight = sourceWidth / targetRatio
        }
        
        // Kırpma dikdörtgenini hesapla (görüntünün merkezinden)
        let cropX = (sourceWidth - newWidth) / 2
        let cropY = (sourceHeight - newHeight) / 2
        
        // Kırpma işlemi
        let cropRect = CGRect(x: cropX, y: cropY, width: newWidth, height: newHeight)
        let sourceCGImage = image.cgImage!
        let croppedCGImage = sourceCGImage.cropping(to: cropRect)!
        
        // Kırpılmış görseli oluştur
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        
        // Görseli hedef boyuta yeniden boyutlandır
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
} 
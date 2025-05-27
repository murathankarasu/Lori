import SwiftUI
import FirebaseStorage
import PhotosUI

class MediaManagerViewModel: ObservableObject {
    // Özel Storage bucket URL'i
    private let storage = Storage.storage()
    
    // Resim yönetimi
    @Published var selectedImages: [PhotosPickerItem] = []
    @Published var processedImages: [UIImage] = []
    @Published var tempImageUrls: [String] = []
    @Published var tempImagePaths: [String] = []
    @Published var selectedImageURL: URL?
    @Published var selectedImagePath: String?
    
    // Video yönetimi
    @Published var selectedVideos: [PhotosPickerItem] = []
    @Published var processedVideos: [URL] = []
    
    let maxImages = 4
    
    func processSelectedImages() async {
        // Eğer hiç görsel seçilmediyse işlemi atla
        if selectedImages.isEmpty {
            return
        }
        
        for item in selectedImages {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    // Resim boyutu kontrolü
                    let maxSize: CGFloat = 2048
                    let resizedImage = image.resized(to: CGSize(width: maxSize, height: maxSize))
                    await MainActor.run {
                        processedImages.append(resizedImage)
                    }
                }
            } catch {
                print("Resim işlenirken hata oluştu: \(error.localizedDescription)")
            }
        }
        
        // İşlem bitince seçimi temizle
        await MainActor.run {
            selectedImages = []
        }
    }
    
    func processSelectedVideos() async {
        if selectedVideos.isEmpty {
            return
        }
        
        for item in selectedVideos {
            if let videoData = try? await item.loadTransferable(type: Data.self),
               let tempURL = saveTemporaryVideo(data: videoData) {
                await MainActor.run {
                    processedVideos.append(tempURL)
                }
            }
        }
        
        // İşlem bitince seçimi temizle
        await MainActor.run {
            selectedVideos = []
        }
    }
    
    private func saveTemporaryVideo(data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(UUID().uuidString).mov"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Video kaydetme hatası: \(error)")
            return nil
        }
    }
    
    func processMedia() async {
        // Burada gerekirse ek medya işlemleri yapılabilir
        // Şu anda processedImages ve processedVideos kullanıma hazır
    }
    
    func finalizeMediaUpload() async -> [String] {
        // Geçici resimleri kalıcı konuma taşı ve URL listesini döndür
        var finalURLs: [String] = []
        
        print("finalizeMediaUpload başlatıldı")
        print("Geçici resim yolları: \(tempImagePaths)")
        print("İşlenmiş resim sayısı: \(processedImages.count)")
        
        // 1. Geçici URL'leri doğrudan değil, kalıcı konuma taşıyarak kullan
        for (index, path) in tempImagePaths.enumerated() {
            do {
                let permanentURL = try await moveToPermanentStorage(path: path)
                finalURLs.append(permanentURL)
                print("[\(index+1)/\(tempImagePaths.count)] Resim URL'si eklendi: \(permanentURL)")
            } catch {
                print("[\(index+1)/\(tempImagePaths.count)] Resim taşıma hatası: \(error)")
                
                // Hata durumunda, direkt olarak URL'yi eklemeyi dene
                if path.starts(with: "posts/") {
                    // Firebase Storage URL formatında direkt string oluştur
                    let bucketName = "lorien-app-tr.firebasestorage.app"
                    let encodedPath = path.replacingOccurrences(of: "/", with: "%2F")
                    let storageURL = "https://firebasestorage.googleapis.com/v0/b/\(bucketName)/o/\(encodedPath)?alt=media"
                    
                    finalURLs.append(storageURL)
                    print("Alternatif URL eklendi: \(storageURL)")
                }
            }
        }
        
        // 2. UI resimlerini de yükle
        for (index, image) in processedImages.enumerated() {
            do {
                let imageURL = try await uploadImage(image)
                finalURLs.append(imageURL)
                print("[\(index+1)/\(processedImages.count)] İşlenmiş resim URL'si eklendi: \(imageURL)")
            } catch {
                print("[\(index+1)/\(processedImages.count)] Resim yükleme hatası: \(error)")
            }
        }
        
        print("finalizeMediaUpload tamamlandı, toplam URL sayısı: \(finalURLs.count)")
        return finalURLs
    }
    
    private func moveToPermanentStorage(path: String) async throws -> String {
        // Hata ayıklama için loglama yapalım
        print("moveToPermanentStorage çağrıldı, path: \(path)")
        
        // Eğer dosya yolu zaten "posts/" ile başlıyorsa, 
        // dosya zaten doğru konumda demektir, direkt URL'yi dön
        if path.starts(with: "posts/") {
            print("Dosya zaten 'posts/' altında, direkt URL'yi döndürüyorum: \(path)")
            do {
                let imageRef = storage.reference(withPath: path)
                // Dosyanın var olduğunu doğrulayalım
                _ = try await imageRef.getMetadata()
                let downloadURL = try await imageRef.downloadURL()
                print("Dosya URL'si başarıyla alındı: \(downloadURL.absoluteString)")
                return downloadURL.absoluteString
            } catch {
                print("Dosya bulunamadı veya URL alınamadı: \(error)")
                
                // Dosya bulunamadı, bu durumda URL'yi direkt oluşturalım
                // Firebase Storage'da bulunamayan dosyalar için alternatif bir çözüm
                let encodedPath = path.replacingOccurrences(of: "/", with: "%2F")
                let storageUrl = "https://firebasestorage.googleapis.com/v0/b/lorien-app-tr.firebasestorage.app/o/\(encodedPath)?alt=media"
                print("Dosya bulunamadı, oluşturulan URL: \(storageUrl)")
                return storageUrl
            }
        }
        
        // Path'i analiz et ve düzelt
        let fileName = path.split(separator: "/").last ?? "unknown.jpg"
        let userId = path.split(separator: "/").dropLast().last ?? "unknown"
        
        // Yeni path oluştur
        let newPath = "posts/\(userId)/\(fileName)"
        print("Yeni path oluşturuldu: \(newPath)")
        
        // Dosyanın varlığını kontrol et ve varsa kopyala
        do {
            // Kaynaktaki dosyayı al
            let tempRef = storage.reference(withPath: path)
            
            // Varlık kontrolü
            do {
                // Dosyanın metadata'sını alarak varlığını kontrol et
                _ = try await tempRef.getMetadata()
                print("Kaynak dosya mevcut, kopyalama işlemi devam ediyor")
                
                // Veriyi al
                let data = try await tempRef.data(maxSize: 10 * 1024 * 1024)
                print("Dosya verisi alındı, boyut: \(data.count) bytes")
                
                // Hedef referansı oluştur
                let postsRef = storage.reference(withPath: newPath)
                
                // Dosyayı yükle
                _ = try await postsRef.putDataAsync(data)
                let downloadURL = try await postsRef.downloadURL()
                
                print("Dosya kalıcı depoya taşındı: \(path) -> \(newPath)")
                print("Yeni URL: \(downloadURL.absoluteString)")
                
                // Başarılı olursa kaynağı silmeyi dene (silme başarısız olsa bile devam et)
                do {
                    try await tempRef.delete()
                    print("Kaynak dosya silindi: \(path)")
                } catch {
                    print("Kaynak dosya silinemedi, ancak işlem devam ediyor: \(error)")
                }
                
                return downloadURL.absoluteString
            } catch {
                // Dosya bulunamadı - Alternatif çözüm
                print("Kaynak dosya bulunamadı, direkt URL döndürülüyor")
                
                // Hedef dosya yoluna göre URL oluştur
                let encodedNewPath = newPath.replacingOccurrences(of: "/", with: "%2F")
                let storageUrl = "https://firebasestorage.googleapis.com/v0/b/lorien-app-tr.firebasestorage.app/o/\(encodedNewPath)?alt=media"
                print("Oluşturulan URL: \(storageUrl)")
                
                return storageUrl
            }
        } catch {
            print("Dosya taşıma hatası: \(error)")
            throw error
        }
    }
    
    private func uploadImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "Resim verisine dönüştürülemedi", code: 400)
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let storagePath = "posts/\(fileName)"
        let storageRef = storage.reference().child(storagePath)
        
        _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func deleteSingleTempImage(path: String) async {
        do {
            let imageRef = storage.reference(withPath: path)
            
            // Önce dosyanın var olup olmadığını kontrol et
            do {
                _ = try await imageRef.getMetadata()
                // Dosya var, silmeye devam et
                try await imageRef.delete()
                print("Görsel silindi: \(path)")
            } catch {
                // Dosya yok veya erişilemiyor, sadece log düş
                print("Görsel silinemedi (mevcut değil): \(path)")
            }
        } catch {
            print("Görsel silme işleminde hata: \(error)")
        }
    }
    
    func cleanupTempImages() async {
        for path in tempImagePaths {
            await deleteSingleTempImage(path: path)
        }
        // Temizlik işlemi tamamlandıktan sonra dizileri boşalt
        await MainActor.run {
            tempImagePaths = []
            tempImageUrls = []
        }
    }
}

// UIImage uzantısı - resim boyutlandırma için
extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Orijinal resim zaten hedef boyuttan küçükse, doğrudan döndür
        if size.width < targetSize.width && size.height < targetSize.height {
            return self
        }
        
        // En-boy oranını koruyarak boyutlandır
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? self
    }
} 
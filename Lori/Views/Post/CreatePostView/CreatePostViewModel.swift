import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

enum PostError: LocalizedError {
    case hateSpeechError(String)
    case networkError(String)
    case uploadError(String)
    case invalidContent(String)
    case imageError(String)
    case authError(String)
    
    var errorDescription: String? {
        switch self {
        case .hateSpeechError(let message):
            return "Nefret Söylemi Kontrolü: \(message)"
        case .networkError(let message):
            return "Bağlantı Hatası: \(message)"
        case .uploadError(let message):
            return "Yükleme Hatası: \(message)"
        case .invalidContent(let message):
            return "İçerik Hatası: \(message)"
        case .imageError(let message):
            return "Resim Hatası: \(message)"
        case .authError(let message):
            return "Kimlik Doğrulama Hatası: \(message)"
        }
    }
}

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var postContent: String = ""
    @Published var selectedImages: [PhotosPickerItem] = []
    @Published var processedImages: [UIImage] = []
    @Published var isPosting = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showHateSpeechWarning = false
    @Published var isCheckingHateSpeech = false
    @Published var isHateSpeechDetected = false
    @Published var isLoading = false
    
    let maxImages = 4
    let maxContentLength = 500
    
    private var debounceTimer: Timer?
    
    var canPost: Bool {
        !postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isPosting &&
        !isCheckingHateSpeech
    }
    
    func processSelectedImages() async {
        processedImages = []
        
        for item in selectedImages {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    // Resim boyutu kontrolü
                    let maxSize: CGFloat = 2048
                    let resizedImage = image.resized(to: CGSize(width: maxSize, height: maxSize))
                    processedImages.append(resizedImage)
                } else {
                    throw PostError.imageError("Resim yüklenemedi")
                }
            } catch {
                showError = true
                errorMessage = PostError.imageError("Resim işlenirken hata oluştu: \(error.localizedDescription)").localizedDescription
            }
        }
    }
    
    func checkHateSpeech() async throws -> (Bool, String, Double) {
        let trimmedContent = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return (false, "", 0.0) }
        
        // Önce CSV tabanlı kontrol
        let localCheck = HateSpeechService.shared.checkLocalHateSpeech(trimmedContent)
        if localCheck.containsHateSpeech {
            return (true, localCheck.category ?? "Nefret Söylemi", 1.0)
        }
        
        // CSV kontrolü başarısız olursa API kontrolü
        do {
            let response = try await HateSpeechService.shared.checkHateSpeech(text: trimmedContent)
            
            // API'den gelen category değeri "0" ise nefret söylemi değil, "1" ise nefret söylemi
            let isHateSpeech = response.data.category == "1"
            let category = isHateSpeech ? "Nefret Söylemi" : "Güvenli"
            
            return (isHateSpeech, category, response.data.confidence)
        } catch {
            print("Nefret söylemi kontrolü hatası: \(error)")
            // Hata durumunda varsayılan olarak güvenli kabul edelim
            return (false, "Güvenli", 0.0)
        }
    }
    
    func createPost() async throws {
        guard canPost else { return }
        
        isPosting = true
        defer { isPosting = false }
        
        do {
            // Kullanıcı kontrolü
            guard let user = Auth.auth().currentUser else {
                throw PostError.authError("Oturum açmanız gerekiyor")
            }
            
            // Kullanıcı bilgilerini Firebase'den al
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            guard let userData = userDoc.data(),
                  let username = userData["username"] as? String else {
                throw PostError.authError("Kullanıcı bilgileri alınamadı")
            }
            
            // Kullanıcının ilgi alanlarını al
            let userInterests = (userData["interests"] as? [String]) ?? []
            
            // İçerik kontrolü
            let trimmedContent = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedContent.isEmpty else {
                throw PostError.invalidContent("Gönderi içeriği boş olamaz")
            }
            
            // Nefret söylemi kontrolü
            let (isHateSpeech, category, confidence) = try await checkHateSpeech()
            if isHateSpeech {
                throw PostError.hateSpeechError("Nefret söylemi tespit edildi. Kategori: \(category)")
            }
            
            // Etiketleri çıkar
            let words = trimmedContent.split(separator: " ")
            var tags: [String] = []
            
            // @ ile başlayan kullanıcı etiketlerini bul
            let userMentions = words.filter { $0.hasPrefix("@") }
                .map { String($0.dropFirst()) }
            
            // # ile başlayan hashtag'leri bul
            let hashtags = words.filter { $0.hasPrefix("#") }
                .map { String($0.dropFirst()) }
            
            // Etiketleri birleştir
            tags = userMentions + hashtags
            
            // Gönderi ID'si oluştur
            let postId = UUID().uuidString
            
            // Gönderi verilerini hazırla
            var postData: [String: Any] = [
                "id": postId,
                "userId": user.uid,
                "username": username,
                "content": trimmedContent,
                "timestamp": Timestamp(date: Date()),
                "likes": 0,
                "comments": [],
                "tags": tags,
                "interests": userInterests
            ]
            
            print("\n=== Gönderi Oluşturma ===")
            print("Gönderi ID: \(postId)")
            print("Kullanıcı ID: \(user.uid)")
            print("Kullanıcı Adı: \(username)")
            print("İçerik: \(trimmedContent)")
            print("Etiketler: \(tags)")
            
            // Resimleri yükle
            if !processedImages.isEmpty {
                var imageUrls: [String] = []
                for (index, image) in processedImages.enumerated() {
                    do {
                        if let imageData = image.jpegData(compressionQuality: 0.7) {
                            let imageName = "\(postId)_\(index).jpg"
                            let storageRef = Storage.storage().reference().child("posts/\(imageName)")
                            
                            _ = try await storageRef.putDataAsync(imageData)
                            let url = try await storageRef.downloadURL()
                            imageUrls.append(url.absoluteString)
                        } else {
                            throw PostError.imageError("Resim sıkıştırılamadı")
                        }
                    } catch {
                        throw PostError.uploadError("Resim yüklenirken hata oluştu: \(error.localizedDescription)")
                    }
                }
                
                // İlk resmi imageUrl olarak kaydet
                if let firstImageUrl = imageUrls.first {
                    postData["imageUrl"] = firstImageUrl
                    postData["imageUrls"] = imageUrls // Tüm resim URL'lerini de kaydet
                }
            }
            
            // Firebase'e kaydet
            try await db.collection("posts").document(postId).setData(postData)
            
            print("✅ Gönderi başarıyla kaydedildi")
            print("===================\n")
            
            // Başarılı gönderi sonrası temizlik
            clearPost()
            
        } catch let error as PostError {
            print("\n❌ Gönderi oluşturma hatası: \(error.localizedDescription)")
            showError = true
            errorMessage = error.localizedDescription
        } catch {
            print("\n❌ Beklenmeyen hata: \(error.localizedDescription)")
            showError = true
            errorMessage = PostError.uploadError(error.localizedDescription).localizedDescription
        }
    }
    
    func clearPost() {
        postContent = ""
        selectedImages = []
        processedImages = []
        showHateSpeechWarning = false
        isPosting = false
        isCheckingHateSpeech = false
    }
}

// UIImage extension for resizing
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
} 
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
    case mediaAnalysisError(String)
    
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
        case .mediaAnalysisError(let message):
            return "Medya Analiz Hatası: \(message)"
        }
    }
}

@MainActor
class CreatePostViewModel: ObservableObject {
    // Özel Storage bucket URL'i
    private let storage = Storage.storage(url: "gs://lorien-app-tr.firebasestorage.app")
    
    @Published var postContent: String = ""
    @Published var selectedImages: [PhotosPickerItem] = []
    @Published var processedImages: [UIImage] = []
    @Published var selectedVideos: [PhotosPickerItem] = []
    @Published var processedVideos: [URL] = []
    @Published var isPosting = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showHateSpeechWarning = false
    @Published var isCheckingHateSpeech = false
    @Published var isHateSpeechDetected = false
    @Published var isLoading = false
    @Published var isCheckingDisinformation = false
    @Published var disinformationCheckResult: DisinformationResponse?
    
    let maxImages = 4
    let maxContentLength = 500
    
    private var debounceTimer: Timer?
    
    private let disinformationService = DisinformationService()
    private let emotionService = EmotionService.shared
    private let userEmotionService = UserEmotionService.shared
    private let mediaAnalysisService = MediaAnalysisService()
    private let keywordAnalysisService = KeywordAnalysisService.shared
    
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
            
            // SADECE category == "1" ise nefret söylemi olarak kabul et
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
            let profileImageUrl = userData["profileImageUrl"] as? String
            
            // Kullanıcının ilgi alanlarını al
            let userInterests = (userData["interests"] as? [String]) ?? []
            
            // İçerik kontrolü
            let trimmedContent = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedContent.isEmpty else {
                throw PostError.invalidContent("Gönderi içeriği boş olamaz")
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

            // Duygu analizi (her iki akışta da kullanılacak)
            let emotionAnalysis = try await emotionService.analyzeEmotion(text: trimmedContent)

            // Nefret söylemi kontrolü
            let (isHateSpeech, category, confidence) = try await checkHateSpeech()
            if isHateSpeech {
                // 1. Nefret söylemi içeren postu ayrı koleksiyona kaydet
                let hateSpeechPostId = UUID().uuidString
                var hateSpeechData: [String: Any] = [
                    "userId": user.uid,
                    "username": username,
                    "content": trimmedContent,
                    "profileImageUrl": profileImageUrl ?? "",
                    "timestamp": Timestamp(date: Date()),
                    "tags": tags,
                    "interests": userInterests,
                    "hateSpeechCategory": category,
                    "hateSpeechConfidence": confidence,
                    "emotionAnalysis": [
                        "emotion": emotionAnalysis.emotion,
                        "confidence": emotionAnalysis.confidence,
                        "timestamp": Timestamp(date: emotionAnalysis.timestamp)
                    ]
                ]

                // === Anahtar kelime analizi ===
                var allKeywords: [String] = []
                do {
                    let textKeywords = try await keywordAnalysisService.analyzeText(trimmedContent)
                    allKeywords.append(contentsOf: textKeywords)
                } catch {
                    print("Metin anahtar kelime analizi hatası: \(error)")
                }
                if !processedImages.isEmpty {
                    for image in processedImages {
                        do {
                            let imageKeywords = try await keywordAnalysisService.analyzeImage(image)
                            allKeywords.append(contentsOf: imageKeywords)
                        } catch {
                            print("Görsel anahtar kelime analizi hatası: \(error)")
                        }
                    }
                }
                if !allKeywords.isEmpty {
                    hateSpeechData["keywords"] = allKeywords
                }

                // Resimleri yükle
                if !processedImages.isEmpty {
                    var imageUrls: [String] = []
                    for (index, image) in processedImages.enumerated() {
                        // Resim verisini analiz et
                        if let imageData = image.jpegData(compressionQuality: 0.7) {
                            do {
                                let isSafe = try await mediaAnalysisService.analyzeImageData(imageData)
                                guard isSafe else {
                                    throw PostError.mediaAnalysisError("Resim içeriği politikalarımıza uygun değil.")
                                }
                            } catch {
                                throw PostError.mediaAnalysisError("Resim analizi sırasında hata: \(error.localizedDescription)")
                            }
                        }
                        do {
                            if let imageData = image.jpegData(compressionQuality: 0.7) {
                                let imageName = "\(hateSpeechPostId)_\(index).jpg"
                                let storageRef = storage.reference().child("hateSpeechPosts/\(imageName)")
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
                        hateSpeechData["imageUrl"] = firstImageUrl
                        hateSpeechData["imageUrls"] = imageUrls // Tüm resim URL'lerini de kaydet
                    }
                }

                // Videoları yükle (eğer varsa)
                if !processedVideos.isEmpty {
                    var videoUrls: [String] = []
                    for (index, url) in processedVideos.enumerated() {
                        do {
                            let data = try Data(contentsOf: url)
                            // Video verisini analiz et
                            do {
                                let isSafe = try await mediaAnalysisService.analyzeVideoData(data)
                                guard isSafe else {
                                    throw PostError.mediaAnalysisError("Video içeriği politikalarımıza uygun değil.")
                                }
                            } catch {
                                throw PostError.mediaAnalysisError("Video analizi sırasında hata: \(error.localizedDescription)")
                            }
                            let videoName = "\(hateSpeechPostId)_video_\(index).mp4"
                            let storageRef = storage.reference().child("hateSpeechPosts/\(videoName)")
                            _ = try await storageRef.putDataAsync(data)
                            let downloadUrl = try await storageRef.downloadURL()
                            videoUrls.append(downloadUrl.absoluteString)
                        } catch {
                            throw PostError.uploadError("Video yüklenirken hata oluştu: \(error.localizedDescription)")
                        }
                    }
                    // İlk videoyu videoUrl olarak kaydet
                    if let firstVideoUrl = videoUrls.first {
                        hateSpeechData["videoUrl"] = firstVideoUrl
                        hateSpeechData["videoUrls"] = videoUrls
                    }
                }

                print("Firestore'a hateSpeechPosts koleksiyonuna kaydedilecek: \(hateSpeechData)")
                do {
                    try await db.collection("hateSpeechPosts").document(hateSpeechPostId).setData(hateSpeechData)
                    print("Firestore'a hateSpeechPosts koleksiyonuna başarıyla kaydedildi!")
                } catch {
                    print("Firestore'a hateSpeechPosts koleksiyonuna kaydedilemedi: \(error)")
                }

                // 2. Duygu analizi yap ve userEmotionInteractions'a ekle
                try await userEmotionService.saveInteraction(
                    userId: user.uid,
                    postId: hateSpeechPostId,
                    interactionType: .create,
                    emotion: emotionAnalysis.emotion,
                    confidence: emotionAnalysis.confidence
                )
                // 3. Kullanıcıya hata fırlatmak yerine, uygun bir mesaj göster
                throw PostError.hateSpeechError("Nefret söylemi tespit edildi ve ayrı koleksiyona kaydedildi. Kategori: \(category)")
            }
            
            // Gönderi ID'si oluştur
            let postId = UUID().uuidString
            
            // Gönderi verilerini hazırla
            var postData: [String: Any] = [
                "userId": user.uid,
                "username": username,
                "content": trimmedContent,
                "profileImageUrl": profileImageUrl ?? "",
                "timestamp": Timestamp(date: Date()),
                "likes": 0,
                "comments": [],
                "tags": tags,
                "interests": userInterests,
                "emotionAnalysis": [
                    "emotion": emotionAnalysis.emotion,
                    "confidence": emotionAnalysis.confidence,
                    "timestamp": Timestamp(date: emotionAnalysis.timestamp)
                ]
            ]
            
            // === Anahtar kelime analizi ===
            var allKeywords: [String] = []
            do {
                let textKeywords = try await keywordAnalysisService.analyzeText(trimmedContent)
                allKeywords.append(contentsOf: textKeywords)
            } catch {
                print("Metin anahtar kelime analizi hatası: \(error)")
            }
            if !processedImages.isEmpty {
                for image in processedImages {
                    do {
                        let imageKeywords = try await keywordAnalysisService.analyzeImage(image)
                        allKeywords.append(contentsOf: imageKeywords)
                    } catch {
                        print("Görsel anahtar kelime analizi hatası: \(error)")
                    }
                }
            }
            if !allKeywords.isEmpty {
                postData["keywords"] = allKeywords
            }
            
            print("\n=== Gönderi Oluşturma ===")
            print("Gönderi ID: \(postId)")
            print("Kullanıcı ID: \(user.uid)")
            print("Kullanıcı Adı: \(username)")
            print("İçerik: \(trimmedContent)")
            print("Etiketler: \(tags)")
            print("Duygu Analizi: \(emotionAnalysis.emotion) (Güven: \(emotionAnalysis.confidence))")
            
            // Resimleri yükle
            if !processedImages.isEmpty {
                var imageUrls: [String] = []
                for (index, image) in processedImages.enumerated() {
                    // Resim verisini analiz et
                    if let imageData = image.jpegData(compressionQuality: 0.7) {
                        do {
                            let isSafe = try await mediaAnalysisService.analyzeImageData(imageData)
                            guard isSafe else {
                                throw PostError.mediaAnalysisError("Resim içeriği politikalarımıza uygun değil.")
                            }
                        } catch {
                            throw PostError.mediaAnalysisError("Resim analizi sırasında hata: \(error.localizedDescription)")
                        }
                    }
                    do {
                        if let imageData = image.jpegData(compressionQuality: 0.7) {
                            let imageName = "\(postId)_\(index).jpg"
                            let storageRef = storage.reference().child("posts/\(imageName)")
                            
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
            
            // Videoları yükle (eğer varsa)
            if !processedVideos.isEmpty {
                var videoUrls: [String] = []
                for (index, url) in processedVideos.enumerated() {
                    do {
                        let data = try Data(contentsOf: url)
                        // Video verisini analiz et
                        do {
                            let isSafe = try await mediaAnalysisService.analyzeVideoData(data)
                            guard isSafe else {
                                throw PostError.mediaAnalysisError("Video içeriği politikalarımıza uygun değil.")
                            }
                        } catch {
                             throw PostError.mediaAnalysisError("Video analizi sırasında hata: \(error.localizedDescription)")
                        }
                        let videoName = "\(postId)_video_\(index).mp4"
                        let storageRef = storage.reference().child("posts/\(videoName)")
                        _ = try await storageRef.putDataAsync(data)
                        let downloadUrl = try await storageRef.downloadURL()
                        videoUrls.append(downloadUrl.absoluteString)
                    } catch {
                        throw PostError.uploadError("Video yüklenirken hata oluştu: \(error.localizedDescription)")
                    }
                }
                // İlk videoyu videoUrl olarak kaydet
                if let firstVideoUrl = videoUrls.first {
                    postData["videoUrl"] = firstVideoUrl
                    postData["videoUrls"] = videoUrls
                }
            }
            
            // Firebase'e kaydet
            try await db.collection("posts").document(postId).setData(postData)
            
            // Etkileşimi kaydet
            try await userEmotionService.saveInteraction(
                userId: user.uid,
                postId: postId,
                interactionType: .create,
                emotion: emotionAnalysis.emotion,
                confidence: emotionAnalysis.confidence
            )
            
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
        selectedVideos = []
        processedVideos = []
        showHateSpeechWarning = false
        isPosting = false
        isCheckingHateSpeech = false
        isCheckingDisinformation = false
        disinformationCheckResult = nil
    }
    
    // Tüm medya dosyalarını seçildiğinde işleyen ortak metod
    func processMedia() async {
        // Reset
        processedImages = []
        processedVideos = []
        // Resimleri işle
        await processSelectedImages()
        // Videoları işle
        await processSelectedVideos()
    }
    
    // Video işleme: geçici URL üzerinden analiz edip ekliyoruz
    func processSelectedVideos() async {
        for item in selectedVideos {
            do {
                if let url = try await item.loadTransferable(type: URL.self) {
                    // Video verisini oku
                    let data = try Data(contentsOf: url)
                    // Uzak serviste analiz et
                    do {
                        let isSafe = try await mediaAnalysisService.analyzeVideoData(data)
                        if isSafe {
                            processedVideos.append(url)
                        } else {
                            // Hata ViewModel'de gösterilecek, burada sadece loglayabiliriz veya doğrudan fırlatabiliriz
                            print("Video analizi: Güvenli değil.")
                            // ViewModel'in kullanıcıya göstermesi için hata fırlatılabilir:
                            throw PostError.mediaAnalysisError("Video içeriği politikalarımıza uygun değil.")
                        }
                    } catch let error as MediaAnalysisError {
                        // Servisten gelen hatayı doğrudan PostError'a çevirebiliriz
                        throw PostError.mediaAnalysisError(error.localizedDescription)
                    } catch {
                        // Diğer beklenmedik hatalar
                        throw PostError.networkError("Video analizi sırasında beklenmedik bir hata oluştu: \(error.localizedDescription)")
                    }
                }
            } catch let postError as PostError {
                 showError = true
                 errorMessage = postError.localizedDescription
            } catch {
                showError = true
                errorMessage = PostError.networkError("Video işlenirken hata: \(error.localizedDescription)").localizedDescription
            }
        }
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
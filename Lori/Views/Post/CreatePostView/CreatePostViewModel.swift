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
    // Medya ve içerik yönetimi için bağımlılıklar
    private let contentValidator: ContentValidationViewModel
    private let mediaManager: MediaManagerViewModel
    
    // Ana gönderim ile ilgili durumlar
    @Published var postContent: String = ""
    @Published var errorMessage: String = ""
    @Published var isPublishing: Bool = false
    @Published var showError = false
    
    // Medya URL'lerini yönetmek için eklenen değişkenler
    @Published var selectedImageUrl: String? = nil 
    @Published var selectedImagePath: String? = nil
    
    // Emoji ve mention bağlantıları
    @Published var selectedEmoji: String?
    @Published var selectedUser: String?
    
    // Servisler
    private let emotionService = EmotionService.shared
    private let userEmotionService = UserEmotionService.shared
    private let mediaAnalysisService = MediaAnalysisService()
    private let keywordAnalysisService = KeywordAnalysisService.shared
    
    init() {
        self.contentValidator = ContentValidationViewModel()
        self.mediaManager = MediaManagerViewModel()
    }
    
    // MediaManager ve ContentValidator için ulaşım metodları
    
    // Content validator
    func checkHateSpeech() async throws -> (Bool, String, Double) {
        return try await contentValidator.checkHateSpeech(text: postContent)
    }
    
    // Media manager
    func processMedia() async {
        await mediaManager.processMedia()
    }
    
    func cleanupTempImages() async {
        await mediaManager.cleanupTempImages()
    }
    
    // Ana gönderim işlemi
    func createPost() async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw PostError.authError("Kullanıcı girişi bulunamadı")
        }
        
        isPublishing = true
        defer { isPublishing = false }
        
        do {
            // Kullanıcı bilgilerini al
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(uid).getDocument()
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

            // Duygu analizi
            let emotionAnalysis = try await emotionService.analyzeEmotion(text: trimmedContent)

            // Anahtar kelime analizi
            var allKeywords: [String] = []
            do {
                let textKeywords = try await keywordAnalysisService.analyzeText(trimmedContent)
                allKeywords.append(contentsOf: textKeywords)
            } catch {
                print("Metin anahtar kelime analizi hatası: \(error)")
            }
            
            // Medya dosyalarını finalleştir
            let imageURLs = await mediaManager.finalizeMediaUpload()
            
            // Post verisi oluştur
            let postRef = Firestore.firestore().collection("posts").document()
            var postData: [String: Any] = [
                "id": postRef.documentID,
                "content": trimmedContent,
                "userId": uid,  // authorId yerine userId kullan (Profile ve FollowingFeed view'ları ile uyumlu olması için)
                "username": username,
                "profileImageUrl": profileImageUrl ?? "",
                "timestamp": FieldValue.serverTimestamp(),
                "tags": tags,
                "interests": userInterests,
                "likes": 0,  // likeCount yerine likes (model ile uyumlu olması için)
                "commentsCount": 0,  // commentCount yerine commentsCount (model ile uyumlu olması için)
                "category": "featured", // Varsayılan olarak featured kategorisine ekle
                "emotionAnalysis": [
                    "emotion": emotionAnalysis.emotion,
                    "confidence": emotionAnalysis.confidence,
                    "timestamp": Timestamp(date: emotionAnalysis.timestamp)
                ]
            ]
            
            // Sadece tek bir resim için URL ekle
            if let singleImageUrl = selectedImageUrl, !singleImageUrl.isEmpty {
                print("MediaSelectionView'dan gelen görsel URL'si: \(singleImageUrl)")
                
                postData["imageUrl"] = singleImageUrl
                
                if let path = selectedImagePath {
                    postData["mainImagePath"] = path
                    print("MediaSelectionView'dan gelen görsel yolu: \(path)")
                }
                
                print("Gönderi için görsel URL'si eklendi")
            } else {
                print("Gönderi için görsel URL'si bulunamadı")
            }
            
            // Anahtar kelimeleri ekle
            if !allKeywords.isEmpty {
                postData["keywords"] = allKeywords
            }
            
            // Firestore'a ekle
            try await postRef.setData(postData)
            
            print("Gönderi başarıyla oluşturuldu: \(postRef.documentID)")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            throw error
        }
    }
} 
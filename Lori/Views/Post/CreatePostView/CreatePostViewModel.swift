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
        let result = try await contentValidator.checkHateSpeech(text: postContent)
        
        // Nefret söylemi tespit edilirse hateSpeechPosts koleksiyonuna kaydet
        if result.0 {
            try await saveHateSpeechRecord(category: result.1, confidence: result.2)
        }
        
        return result
    }
    
    // Nefret söylemi içeren içeriği Firestore'a kaydet
    private func saveHateSpeechRecord(category: String, confidence: Double) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw PostError.authError("Kullanıcı girişi bulunamadı")
        }
        
        do {
            // Kullanıcı bilgilerini al
            let db = Firestore.firestore()
            let userDoc = try await db.collection("users").document(uid).getDocument()
            guard let userData = userDoc.data(),
                  let username = userData["username"] as? String else {
                throw PostError.authError("Kullanıcı bilgileri alınamadı")
            }
            
            // İçeriği doğrula
            let trimmedContent = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedContent.isEmpty else {
                return // Boş içerik olmamalı
            }
            
            // Nefret söylemi kaydı için veri oluştur
            let hateSpeechRef = db.collection("hateSpeechPosts").document()
            var hateSpeechData: [String: Any] = [
                "id": hateSpeechRef.documentID,
                "content": trimmedContent, // Trimlenmiş içerik kullanıldı
                "userId": uid,
                "username": username,
                "timestamp": FieldValue.serverTimestamp(),
                "category": category,
                "confidence": confidence,
                "status": "flagged" // flagged, reviewed, approved, rejected gibi durumlar kullanılabilir
            ]
            
            // Medya URL'sini de ekle (eğer varsa)
            if let imageUrl = selectedImageUrl, !imageUrl.isEmpty {
                hateSpeechData["imageUrl"] = imageUrl
            }
            
            // Firestore'a kaydet
            try await hateSpeechRef.setData(hateSpeechData)
            print("Nefret söylemi içeriği kaydedildi: \(hateSpeechRef.documentID)")
            
        } catch {
            print("Nefret söylemi kaydı sırasında hata: \(error.localizedDescription)")
            throw error
        }
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

            // Duygu analizi - post oluşturma için API çağrısı yapalım
            var emotionAnalysis: EmotionAnalysis
            do {
                emotionAnalysis = try await emotionService.analyzeEmotion(text: trimmedContent, operationType: .postCreation)
            } catch {
                print("⚠️ Duygu analizi sırasında hata oluştu, rastgele duygu kullanılacak")
                // Hata durumunda rastgele duygu kullanılacak (EmotionService içinde hallediliyor)
                emotionAnalysis = try await emotionService.analyzeEmotion(text: trimmedContent, operationType: .postCreation)
            }

            // Anahtar kelime analizi
            var allKeywords: [String] = []
            do {
                let textKeywords = try await keywordAnalysisService.analyzeText(trimmedContent, operationType: .postCreation)
                allKeywords.append(contentsOf: textKeywords)
            } catch {
                print("⚠️ Anahtar kelime analizi sırasında hata oluştu, metinden kelimeler çıkarılacak")
                // Hata durumunda metinden kelimeler çıkarılacak (KeywordAnalysisService içinde hallediliyor)
                allKeywords = try await keywordAnalysisService.analyzeText(trimmedContent, operationType: .postCreation)
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
                "viewCount": 0, // Görüntülenme sayısını başlangıçta 0 olarak ayarla
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
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
    private let apiURL = "http://localhost:8000/api/check-hate-speech"
    
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
    
    func handleContentChange() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.checkHateSpeech()
            }
        }
    }
    
    func checkHateSpeech() async {
        guard !postContent.isEmpty else { return }
        
        isCheckingHateSpeech = true
        defer { isCheckingHateSpeech = false }
        
        do {
            let response = try await checkHateSpeech(text: postContent)
            if response.data.isHateSpeech {
                showHateSpeechWarning = true
                
                // Detaylı uyarı mesajı
                let category = response.data.category
                let confidence = Int(response.data.confidence * 100)
                let severity = Int(response.data.details.severityScore * 100)
                let details = response.data.details.categoryDetails.joined(separator: ", ")
                
                errorMessage = """
                Bu içerik nefret söylemi içeriyor olabilir:
                
                • Kategori: \(category)
                • Güven Skoru: %\(confidence)
                • Ciddiyet: %\(severity)
                • Tespit Edilen Öğeler: \(details)
                
                Lütfen içeriğinizi gözden geçirin.
                """
            }
        } catch {
            print("Nefret söylemi kontrolünde hata: \(error)")
            showError = true
            errorMessage = PostError.hateSpeechError(error.localizedDescription).localizedDescription
        }
    }
    
    func checkHateSpeech(text: String) async throws -> HateSpeechResponse {
        guard let url = URL(string: apiURL) else {
            throw URLError(.badURL)
        }
        
        let body = ["text": text]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(HateSpeechResponse.self, from: data)
        
        DispatchQueue.main.async {
            self.isHateSpeechDetected = result.data.isHateSpeech
        }
        
        return result
    }
    
    func createPost() async {
        guard canPost else { return }
        
        isPosting = true
        defer { isPosting = false }
        
        do {
            // Kullanıcı kontrolü
            guard let user = Auth.auth().currentUser else {
                throw PostError.authError("Oturum açmanız gerekiyor")
            }
            
            // İçerik kontrolü
            let trimmedContent = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedContent.isEmpty else {
                throw PostError.invalidContent("Gönderi içeriği boş olamaz")
            }
            
            // Nefret söylemi kontrolü
            let response = try await checkHateSpeech(text: trimmedContent)
            
            if response.data.isHateSpeech {
                showHateSpeechWarning = true
                return
            }
            
            // Gönderi oluştur
            let post = Post(
                id: UUID().uuidString,
                userId: user.uid,
                username: user.displayName ?? "Anonim",
                content: trimmedContent,
                imageUrl: nil,
                timestamp: Date(),
                likes: 0,
                comments: [],
                isViewed: false,
                tags: []
            )
            
            // Firebase'e kaydet
            let db = Firestore.firestore()
            
            var postData: [String: Any] = [
                "id": post.id,
                "userId": post.userId,
                "username": post.username,
                "content": post.content,
                "timestamp": Timestamp(date: post.timestamp),
                "likes": post.likes,
                "comments": [],
                "isViewed": post.isViewed,
                "tags": post.tags,
                "contentAnalysis": [
                    "isHateSpeech": response.data.isHateSpeech,
                    "confidence": response.data.confidence,
                    "category": response.data.category,
                    "severityScore": response.data.details.severityScore
                ]
            ]
            
            // Resimleri yükle
            if !processedImages.isEmpty {
                var imageUrls: [String] = []
                for (index, image) in processedImages.enumerated() {
                    do {
                        if let imageData = image.jpegData(compressionQuality: 0.7) {
                            let imageName = "\(post.id)_\(index).jpg"
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
                }
            }
            
            try await db.collection("posts").document(post.id).setData(postData)
            
            // Başarılı gönderi sonrası temizlik
            clearPost()
            
        } catch let error as PostError {
            showError = true
            errorMessage = error.localizedDescription
        } catch {
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
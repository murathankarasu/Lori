import Foundation
import Firebase
import FirebaseStorage
import UIKit

class DirectMessageMediaService: ObservableObject {
    static let shared = DirectMessageMediaService()
    
    private let storage = Storage.storage()
    
    private init() {}
    
    // Resim yükle ve URL döndür
    func uploadImage(_ image: UIImage, conversationId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "DirectMessageMediaService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Resim dönüştürülemedi"])
        }
        
        let imageId = UUID().uuidString
        let storageRef = storage.reference()
            .child("direct_message_images")
            .child(conversationId)
            .child("\(imageId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
} 
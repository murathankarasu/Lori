import Foundation
import FirebaseFirestore // Timestamp için gerekli olabilir

struct User: Identifiable, Codable {
    let id: String // Veya Firestore ID'si için @DocumentID var id: String?
    let username: String
    let email: String
    let profileImageUrl: String?
    let bio: String?
    let followers: Int // Orijinal Int tipine geri dönülüyor
    let following: Int // Orijinal Int tipine geri dönülüyor
    let createdAt: Date // Orijinal Date tipine geri dönülüyor
    let isVerified: Bool // Orijinal Bool tipine geri dönülüyor
    let usernameLower: String // Küçük harfli kullanıcı adı (arama için)
    // uid alanı orijinal modelde yoksa kaldırılabilir
    
    // Orijinal modelde CodingKeys yoksa veya farklıysa ona göre düzenlenmeli
    enum CodingKeys: String, CodingKey {
        case id // Firestore'daki alan adıyla eşleşmeli (genellikle documentID)
        case username
        case email
        case profileImageUrl
        case bio
        case followers // Firestore'da bu isimde Int alan yoksa, bu satır sorun yaratabilir
        case following // Firestore'da bu isimde Int alan yoksa, bu satır sorun yaratabilir
        case createdAt
        case isVerified
        case usernameLower
    }
    
    // Kullanıcının geçerli veriye sahip olup olmadığını kontrol eden fonksiyon
    var isValid: Bool {
        return !id.isEmpty && 
               !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Hashable ve Equatable conformansları kaldırılıyor (eğer orijinalde yoksa)
} 
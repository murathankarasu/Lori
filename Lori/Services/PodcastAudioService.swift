import Foundation

/// Podcast ses dosyası oluşturma servisi
/// Bu servis kullanıcının post verilerine dayalı olarak kişiselleştirilmiş podcast ses dosyaları oluşturur
/// Uzak API'ye kullanıcı bilgilerini gönderir ve oluşturulan ses dosyasının URL'sini alır
class PodcastAudioService {
    static let shared = PodcastAudioService()
    private let baseURL = "https://lori-postcast-service-main-services.up.railway.app/"
    private init() {}
    
    /// Kullanıcı için podcast ses dosyası oluşturur
    /// Bu fonksiyon kullanıcının ID'si ve kullanıcı adını kullanarak uzak API'den podcast ses dosyası oluşturur
    /// API'ye POST isteği gönderir ve oluşturulan ses dosyasının public URL'sini döner
    /// Hata durumlarında detaylı loglama yapar ve uygun hata yönetimi sağlar
    /// - Parameters:
    ///   - userID: Podcast oluşturulacak kullanıcının ID'si
    ///   - username: Kullanıcının kullanıcı adı
    ///   - completion: İşlem tamamlandığında çağrılacak closure (başarılı yanıt veya hata)
    func generateAudio(userID: String, username: String, completion: @escaping (Result<PodcastAudioResponse, Error>) -> Void) {
        print("[PodcastAudioService] API çağrılıyor: userID=\(userID), username=\(username)")
        
        // API endpoint URL'sini oluştur
        guard let url = URL(string: baseURL + "generate_audio") else {
            print("[PodcastAudioService] Hatalı URL")
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        
        // HTTP isteği oluştur
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // İstek gövdesini oluştur - kullanıcı bilgilerini JSON formatında gönder
        let body: [String: String] = [
            "user_id": userID,
            "username": username
        ]
        
        do {
            // JSON verisini encode et
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("[PodcastAudioService] JSON encode hatası: \(error)")
            completion(.failure(error))
            return
        }
        
        // URLSession ile asenkron istek gönder
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Ağ hatası kontrolü
            if let error = error {
                print("[PodcastAudioService] API Hatası: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Veri kontrolü
            guard let data = data else {
                print("[PodcastAudioService] API'dan veri gelmedi")
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            do {
                // API yanıtını decode et
                let decoded = try JSONDecoder().decode(PodcastAudioResponse.self, from: data)
                print("[PodcastAudioService] API Başarılı: public_url=\(decoded.public_url)")
                completion(.success(decoded))
            } catch {
                print("[PodcastAudioService] JSON decode hatası: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        // İsteği başlat
        task.resume()
    }
} 
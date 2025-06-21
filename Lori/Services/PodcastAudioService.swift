import Foundation

class PodcastAudioService {
    static let shared = PodcastAudioService()
    private let baseURL = "https://lori-postcast-service-main-services.up.railway.app/"
    private init() {}
    
    func generateAudio(userID: String, username: String, completion: @escaping (Result<PodcastAudioResponse, Error>) -> Void) {
        print("[PodcastAudioService] API çağrılıyor: userID=\(userID), username=\(username)")
        guard let url = URL(string: baseURL + "generate_audio") else {
            print("[PodcastAudioService] Hatalı URL")
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "user_id": userID,
            "username": username
        ]
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("[PodcastAudioService] JSON encode hatası: \(error)")
            completion(.failure(error))
            return
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[PodcastAudioService] API Hatası: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let data = data else {
                print("[PodcastAudioService] API'dan veri gelmedi")
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(PodcastAudioResponse.self, from: data)
                print("[PodcastAudioService] API Başarılı: public_url=\(decoded.public_url)")
                completion(.success(decoded))
            } catch {
                print("[PodcastAudioService] JSON decode hatası: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
} 
import SwiftUI
import FirebaseFirestore

class ContentValidationViewModel: ObservableObject {
    @Published var isCheckingDisinformation: Bool = false
    @Published var disinformationCheckResult: DisinformationResponse?
    @Published var selectedEmoji: String?
    @Published var selectedUser: String?
    
    private let disinformationService = DisinformationService()
    private let hateSpeechService = HateSpeechService.shared
    
    func checkHateSpeech(text: String) async throws -> (Bool, String, Double) {
        let trimmedContent = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return (false, "", 0.0) }
        
        // Önce CSV tabanlı kontrol
        let localCheck = hateSpeechService.checkLocalHateSpeech(trimmedContent)
        if localCheck.containsHateSpeech {
            return (true, localCheck.category ?? "Nefret Söylemi", 1.0)
        }
        
        // CSV kontrolü başarısız olursa API kontrolü
        do {
            let response = try await hateSpeechService.checkHateSpeech(text: trimmedContent)
            
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
    
    func checkDisinformation(text: String) async throws -> DisinformationResponse {
        isCheckingDisinformation = true
        defer { isCheckingDisinformation = false }
        
        let response = try await disinformationService.checkDisinformation(text: text)
        disinformationCheckResult = response
        return response
    }
} 
import Foundation

@MainActor
class GaladrielViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var debugLogs: [String] = []
    
    private let apiKey = "api-key"
    private let apiEndpoint = "https://openrouter.ai/api/v1/chat/completions"
    
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        print(logMessage)
        debugLogs.append(logMessage)
    }
    
    func sendMessage(_ content: String) async {
        addLog("🟢 Mesaj gönderiliyor: \(content)")
        
        do {
            // Önceki mesajları birleştir
            let previousMessages = messages.suffix(5)
            var conversationContext = "Önceki mesajlar:\n"
            for msg in previousMessages {
                conversationContext += "\(msg.isUser ? "Kullanıcı" : "Asistan"): \(msg.content)\n"
            }
            
            // OpenAI API için istek formatı
            let parameters: [String: Any] = [
                "model": "deepseek/deepseek-v3-base:free",
                "messages": [
                    [
                        "role": "system",
                        "content": "Sen Galadriel adında bir AI asistansın. Türkçe konuşuyorsun ve kullanıcılara yardımcı oluyorsun. Her zaman Türkçe yanıt vermelisin."
                    ]
                ] + previousMessages.map { message in
                    [
                        "role": message.isUser ? "user" : "assistant",
                        "content": message.content
                    ]
                } + [
                    [
                        "role": "user",
                        "content": content
                    ]
                ],
                "temperature": 0.7,
                "max_tokens": 150,
                "top_p": 0.9,
                "frequency_penalty": 1.0,
                "presence_penalty": 1.0,
                "transforms": ["middle-out"],
                "route": "fallback"
            ]
            
            addLog("📤 API isteği hazırlanıyor")
            addLog("Endpoint: \(apiEndpoint)")
            
            guard let url = URL(string: apiEndpoint) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("https://lori.app", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("Lori", forHTTPHeaderField: "X-Title")
            request.timeoutInterval = 30
            
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            request.httpBody = jsonData
            
            addLog("📡 API isteği gönderiliyor")
            addLog("Request body: \(String(data: jsonData, encoding: .utf8) ?? "")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                addLog("📥 API yanıtı alındı - Status: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseString = String(data: data, encoding: .utf8) ?? "Yanıt decode edilemedi"
                    addLog("❌ HTTP Hata \(httpResponse.statusCode): \(responseString)")
                    throw NSError(domain: "", code: httpResponse.statusCode, 
                                userInfo: [NSLocalizedDescriptionKey: "HTTP Hata \(httpResponse.statusCode): \(responseString)"])
                }
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "Yanıt decode edilemedi"
            addLog("API Yanıtı: \(responseString)")
            
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = jsonResponse["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let text = message["content"] as? String {
                
                addLog("✅ AI yanıtı başarıyla alındı")
                let aiMessage = Message(id: UUID().uuidString, content: text, isUser: false)
                messages.append(aiMessage)
            } else {
                addLog("❌ API yanıtı beklenen formatta değil")
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "API yanıtı işlenemedi"])
            }
        } catch {
            addLog("❌ Hata oluştu: \(error.localizedDescription)")
            let errorMessage = Message(
                id: UUID().uuidString,
                content: "Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.\nHata detayı: \(error.localizedDescription)",
                isUser: false
            )
            messages.append(errorMessage)
        }
    }
    
    init() {
        addLog("🟢 Galadriel başlatılıyor")
        let welcomeMessage = Message(
            id: UUID().uuidString,
            content: "Merhaba! Ben Galadriel, size nasıl yardımcı olabilirim?",
            isUser: false
        )
        messages.append(welcomeMessage)
        addLog("✅ Hoş geldin mesajı eklendi")
    }
} 

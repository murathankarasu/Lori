import Foundation

@MainActor
class GaladrielViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var debugLogs: [String] = []
    
    private let apiKey = "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"
    private let apiEndpoint = "https://openrouter.ai/api/v1/chat/completions"
    
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        print(logMessage)
        debugLogs.append(logMessage)
    }
    
    func sendMessage(_ content: String, username: String) async {
        addLog("🟢 Sending message: \(content)")
        
        do {
            // Get previous messages
            let previousMessages = messages.suffix(5)
            var conversationContext = "Previous messages:\n"
            for msg in previousMessages {
                conversationContext += "\(msg.isUser ? "User" : "Assistant"): \(msg.content)\n"
            }
            
            // OpenAI API request format
            let parameters: [String: Any] = [
                "model": "mistralai/mistral-7b-instruct",
                "messages": [
                    [
                        "role": "system",
                        "content": "You are Galadriel, an AI assistant. Always respond in English. Address the user by their username (\(username)). Avoid repetition and keep your responses concise and clear."
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
            
            addLog("📤 Preparing API request")
            addLog("Endpoint: \(apiEndpoint)")
            
            guard let url = URL(string: apiEndpoint) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("https://lori.app", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("Lori", forHTTPHeaderField: "X-Title")
            request.setValue("OpenRouter/v1", forHTTPHeaderField: "HTTP-Referer")
            request.timeoutInterval = 30
            
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            request.httpBody = jsonData
            
            addLog("📡 Sending API request")
            addLog("Request body: \(String(data: jsonData, encoding: .utf8) ?? "")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                addLog("📥 API response received - Status: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseString = String(data: data, encoding: .utf8) ?? "Response could not be decoded"
                    addLog("❌ HTTP Error \(httpResponse.statusCode): \(responseString)")
                    throw NSError(domain: "", code: httpResponse.statusCode, 
                                userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode): \(responseString)"])
                }
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "Response could not be decoded"
            addLog("API Response: \(responseString)")
            
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = jsonResponse["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let text = message["content"] as? String {
                
                addLog("✅ AI response received successfully")
                let aiMessage = Message(id: UUID().uuidString, content: text, isUser: false)
                messages.append(aiMessage)
            } else {
                addLog("❌ API response is not in expected format")
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "API response could not be processed"])
            }
        } catch {
            addLog("❌ Error occurred: \(error.localizedDescription)")
            let errorMessage = Message(
                id: UUID().uuidString,
                content: "Sorry, an error occurred. Please try again.\nError details: \(error.localizedDescription)",
                isUser: false
            )
            messages.append(errorMessage)
        }
    }
    
    init() {
        addLog("🟢 Initializing Galadriel")
        let welcomeMessage = Message(
            id: UUID().uuidString,
            content: "Hello! I'm Galadriel, how can I help you today?",
            isUser: false
        )
        messages.append(welcomeMessage)
        addLog("✅ Welcome message added")
    }
} 

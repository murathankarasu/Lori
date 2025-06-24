import Foundation

@MainActor
class GaladrielViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var debugLogs: [String] = []
    
    private let apiKey = "KDkIFj1szU8PneUglhNFAjUIpJlM3Aj3"
    private let apiEndpoint = "https://api.mistral.ai/v1/chat/completions"
    
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        print(logMessage)
        debugLogs.append(logMessage)
    }
    
    func sendMessage(_ content: String, username: String) async {
        addLog("🟢 Sending message: \(content)")
        addLog("📝 Username: \(username)")
        
        do {
            // Get previous messages
            let previousMessages = messages.suffix(5)
            var conversationContext = "Previous messages:\n"
            for msg in previousMessages {
                conversationContext += "\(msg.isUser ? "User" : "Assistant"): \(msg.content)\n"
            }
            
            // Mistral API request format
            let parameters: [String: Any] = [
                "model": "mistral-medium",
                "messages": [
                    [
                        "role": "system",
                        "content": "You are Galadriel, an AI assistant. Respond with deep understanding, warmth, and empathy, like a wise and supportive guide. Instead of being a classic psychologist, gently help the user explore their thoughts and feelings, and offer thoughtful questions or gentle direction to help them find their own path. IMPORTANT: You MUST address the user directly by their username which is '\(username)'. Do not use generic greetings or call the user 'Lori'. Always refer to the user as '\(username)'. Always respond in English. Avoid repetition and keep your responses concise and clear."
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
                "top_p": 0.9
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

import Foundation

struct Message: Identifiable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: String, content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
} 
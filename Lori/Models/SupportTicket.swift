import Foundation
import FirebaseFirestore

struct SupportTicket: Identifiable, Codable {
    var id: String
    let userId: String
    let username: String
    let message: String
    let createdAt: Date
    let status: TicketStatus
    
    enum TicketStatus: String, Codable {
        case pending = "pending"
        case inProgress = "in_progress"
        case resolved = "resolved"
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         username: String,
         message: String,
         createdAt: Date = Date(),
         status: TicketStatus = .pending) {
        self.id = id
        self.userId = userId
        self.username = username
        self.message = message
        self.createdAt = createdAt
        self.status = status
    }
}

extension SupportTicket {
    var dictionary: [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "username": username,
            "message": message,
            "createdAt": Timestamp(date: createdAt),
            "status": status.rawValue
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> SupportTicket? {
        guard let id = dict["id"] as? String,
              let userId = dict["userId"] as? String,
              let username = dict["username"] as? String,
              let message = dict["message"] as? String,
              let timestamp = dict["createdAt"] as? Timestamp,
              let statusRaw = dict["status"] as? String,
              let status = TicketStatus(rawValue: statusRaw) else {
            return nil
        }
        
        return SupportTicket(
            id: id,
            userId: userId,
            username: username,
            message: message,
            createdAt: timestamp.dateValue(),
            status: status
        )
    }
} 
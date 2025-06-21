import Foundation
import FirebaseFirestore
import FirebaseAuth

class SupportTicketService {
    private let db = Firestore.firestore()
    private let collectionName = "support_tickets"
    
    func createTicket(message: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "SupportTicketService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let ticket = SupportTicket(
            userId: currentUser.uid,
            username: currentUser.displayName ?? "Anonymous",
            message: message
        )
        
        try await db.collection(collectionName).document(ticket.id).setData(ticket.dictionary)
    }
    
    func getUserTickets() async throws -> [SupportTicket] {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "SupportTicketService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let snapshot = try await db.collection(collectionName)
            .whereField("userId", isEqualTo: currentUser.uid)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            SupportTicket.fromDictionary(document.data())
        }
    }
    
    func updateTicketStatus(ticketId: String, status: SupportTicket.TicketStatus) async throws {
        try await db.collection(collectionName).document(ticketId).updateData([
            "status": status.rawValue
        ])
    }
    
    func deleteTicket(ticketId: String) async throws {
        try await db.collection(collectionName).document(ticketId).delete()
    }
} 
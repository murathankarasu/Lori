import Foundation

struct Interest: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 
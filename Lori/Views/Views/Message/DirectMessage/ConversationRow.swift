import SwiftUI
import Firebase

// Konuşma satırı görünümü
struct ConversationRow: View {
    let conversation: DirectMessageConversation
    let userId: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar (gerçek uygulamada kullanıcının avatarını yüklemeniz gerekir)
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(otherUserInitial)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Kullanıcı") // Gerçek uygulamada diğer kullanıcının adı
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timeAgoDisplay)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text(displayMessage)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundColor(conversation.lastMessageRead || conversation.lastMessageSenderId == userId ? .gray : .white)
                    
                    Spacer()
                    
                    if !conversation.lastMessageRead && conversation.lastMessageSenderId != userId {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
    }
    
    // Diğer kullanıcının baş harfi (gerçek uygulamada kullanıcı adına göre değiştirilmeli)
    private var otherUserInitial: String {
        "U"
    }
    
    // Mesajı görüntülemek için yardımcı hesaplanan özellik
    private var displayMessage: String {
        if conversation.lastMessageSenderId == userId {
            return "Sen: \(conversation.lastMessage)"
        } else {
            return conversation.lastMessage
        }
    }
    
    // Zaman gösterimi için yardımcı hesaplanan özellik
    private var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: conversation.lastMessageTimestamp, relativeTo: Date())
    }
} 

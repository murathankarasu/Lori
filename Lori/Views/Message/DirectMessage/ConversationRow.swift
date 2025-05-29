import SwiftUI
import Firebase
import Kingfisher

// Konuşma satırı görünümü
struct ConversationRow: View {
    let conversation: DirectMessageConversation
    let userId: String
    let userCache: [String: User]
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar - Kingfisher ile profile resmi gösterimi
            if let user = otherUser, let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                KFImage(URL(string: profileImageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(
                        // Online durumu için yeşil nokta (isteğe bağlı)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .offset(x: 20, y: 20)
                            .opacity(0) // Şimdilik gizli, online durumu eklendiğinde açılabilir
                    )
            } else {
                // Profil resmi yoksa baş harfi göster
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(otherUserInitial)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        // Online durumu için yeşil nokta (isteğe bağlı)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .offset(x: 20, y: 20)
                            .opacity(0) // Şimdilik gizli, online durumu eklendiğinde açılabilir
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(otherUserName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timeAgoDisplay)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text(displayMessage)
                        .lineLimit(2)
                        .font(.system(size: 15))
                        .foregroundColor(.white) // Hep beyaz olsun
                        .fontWeight(conversation.lastMessageRead || conversation.lastMessageSenderId == userId ? .regular : .medium)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        if !conversation.lastMessageRead && conversation.lastMessageSenderId != userId {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                        }
                        
                        // Kamera ikonu (fotoğraf mesajı için)
                        if conversation.lastMessage.contains("📷") {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
    
    // Diğer kullanıcının bilgileri
    private var otherUser: User? {
        let otherUserId = conversation.users.first(where: { $0 != userId })
        return otherUserId != nil ? userCache[otherUserId!] : nil
    }
    
    private var otherUserName: String {
        return otherUser?.username ?? "Kullanıcı"
    }
    
    private var otherUserInitial: String {
        return String(otherUserName.prefix(1).uppercased())
    }
    
    // Mesajı görüntülemek için yardımcı hesaplanan özellik
    private var displayMessage: String {
        let message = conversation.lastMessage
        
        // Mesaj türüne göre özel gösterim
        if message.isEmpty {
            return "Fotoğraf gönderildi 📷"
        }
        
        if conversation.lastMessageSenderId == userId {
            return "Sen: \(message)"
        } else {
            return message
        }
    }
    
    // Zaman gösterimi için yardımcı hesaplanan özellik
    private var timeAgoDisplay: String {
        let now = Date()
        let messageDate = conversation.lastMessageTimestamp
        let calendar = Calendar.current
        
        // Bugün mü kontrol et
        if calendar.isDate(messageDate, inSameDayAs: now) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: messageDate)
        }
        
        // Dün mü kontrol et
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(messageDate, inSameDayAs: yesterday) {
            return "Dün"
        }
        
        // Bu hafta içinde mi kontrol et
        if let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
           messageDate >= weekStart {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: messageDate)
        }
        
        // Daha eski tarihler için tam tarih
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: messageDate)
    }
} 

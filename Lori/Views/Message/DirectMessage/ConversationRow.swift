import SwiftUI
import Firebase
import Kingfisher

// Conversation row view
struct ConversationRow: View {
    let conversation: DirectMessageConversation
    let userId: String
    let userCache: [String: User]
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar - Profile image display with Kingfisher
            if let user = otherUser, let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                KFImage(URL(string: profileImageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(
                        // Green dot for online status (optional)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .offset(x: 20, y: 20)
                            .opacity(0) // Hidden for now, can be enabled when online status is added
                    )
            } else {
                // Show initial if no profile image
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(otherUserInitial)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        // Green dot for online status (optional)
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .offset(x: 20, y: 20)
                            .opacity(0) // Hidden for now, can be enabled when online status is added
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
                        .foregroundColor(.white) // Always white
                        .fontWeight(conversation.lastMessageRead || conversation.lastMessageSenderId == userId ? .regular : .medium)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        if !conversation.lastMessageRead && conversation.lastMessageSenderId != userId {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                        }
                        
                        // Camera icon (for photo message)
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
    
    // Other user's information
    private var otherUser: User? {
        let otherUserId = conversation.users.first(where: { $0 != userId })
        return otherUserId != nil ? userCache[otherUserId!] : nil
    }
    
    private var otherUserName: String {
        return otherUser?.username ?? "User"
    }
    
    private var otherUserInitial: String {
        return String(otherUserName.prefix(1).uppercased())
    }
    
    // Helper computed property for message display
    private var displayMessage: String {
        let message = conversation.lastMessage
        
        // Special display based on message type
        if message.isEmpty {
            return "Photo sent 📷"
        }
        
        if conversation.lastMessageSenderId == userId {
            return "You: \(message)"
        } else {
            return message
        }
    }
    
    // Helper computed property for time display
    private var timeAgoDisplay: String {
        let now = Date()
        let messageDate = conversation.lastMessageTimestamp
        let calendar = Calendar.current
        
        // Check if today
        if calendar.isDate(messageDate, inSameDayAs: now) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: messageDate)
        }
        
        // Check if yesterday
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(messageDate, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        
        // Check if within this week
        if let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
           messageDate >= weekStart {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: messageDate)
        }
        
        // Full date for older dates
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: messageDate)
    }
} 

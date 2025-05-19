import SwiftUI
import Firebase

// Mesaj balonu görünümü
struct MessageBubble: View {
    let message: DirectMessage
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(10)
                    .background(isFromCurrentUser ? Color.blue : Color(UIColor.darkGray))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                
                Text(timeFormatter.string(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
} 

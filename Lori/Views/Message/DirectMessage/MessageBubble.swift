import SwiftUI
import Firebase

// Mesaj balonu görünümü
struct MessageBubble: View {
    let message: DirectMessage
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        if !message.isRead && isFromCurrentUser {
                            Text("İletildi")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                        } else if message.isRead && isFromCurrentUser {
                            Text("Görüldü")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                        }
                        
                        Text(timeFormatter.string(from: message.timestamp))
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                    
                    Text(message.content)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(
                            MessageBubbleShape(isFromCurrentUser: true)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(
                            MessageBubbleShape(isFromCurrentUser: false)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    Text(timeFormatter.string(from: message.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .padding(.leading, 4)
                }
                
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

// Özel mesaj balonu şekli
struct MessageBubbleShape: Shape {
    let isFromCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()
        let cornerRadius: CGFloat = 18
        let tailSize: CGFloat = 6
        
        if isFromCurrentUser {
            // Sağ taraf (gönderen)
            path.move(to: CGPoint(x: cornerRadius, y: 0))
            path.addLine(to: CGPoint(x: rect.width - cornerRadius - tailSize, y: 0))
            path.addQuadCurve(to: CGPoint(x: rect.width - tailSize, y: cornerRadius), 
                             controlPoint: CGPoint(x: rect.width - tailSize, y: 0))
            path.addLine(to: CGPoint(x: rect.width - tailSize, y: rect.height - cornerRadius - tailSize))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width - tailSize - cornerRadius, y: rect.height))
            path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
            path.addQuadCurve(to: CGPoint(x: 0, y: rect.height - cornerRadius), 
                             controlPoint: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: cornerRadius))
            path.addQuadCurve(to: CGPoint(x: cornerRadius, y: 0), 
                             controlPoint: CGPoint(x: 0, y: 0))
        } else {
            // Sol taraf (alıcı)
            path.move(to: CGPoint(x: cornerRadius + tailSize, y: 0))
            path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
            path.addQuadCurve(to: CGPoint(x: rect.width, y: cornerRadius), 
                             controlPoint: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
            path.addQuadCurve(to: CGPoint(x: rect.width - cornerRadius, y: rect.height), 
                             controlPoint: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: cornerRadius + tailSize, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: tailSize, y: rect.height - cornerRadius - tailSize))
            path.addLine(to: CGPoint(x: tailSize, y: cornerRadius))
            path.addQuadCurve(to: CGPoint(x: cornerRadius + tailSize, y: 0), 
                             controlPoint: CGPoint(x: tailSize, y: 0))
        }
        
        path.close()
        return Path(path.cgPath)
    }
} 

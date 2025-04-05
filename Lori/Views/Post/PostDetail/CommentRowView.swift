import SwiftUI

struct CommentRowView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                
                Text(comment.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(comment.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(comment.content)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
} 
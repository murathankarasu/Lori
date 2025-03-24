import SwiftUI

struct CommentView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading) {
                    Text(comment.username)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text(comment.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Text(comment.content)
                .font(.body)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

struct CommentView_Previews: PreviewProvider {
    static var previews: some View {
        CommentView(
            comment: Comment(
                id: "1",
                userId: "user1",
                username: "Test Kullanıcı",
                content: "Test yorum içeriği",
                timestamp: Date()
            )
        )
        .preferredColorScheme(.dark)
    }
} 
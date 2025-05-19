import SwiftUI

struct CommentView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.username)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(comment.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            Text(comment.content)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct CommentView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            CommentView(
                comment: Comment(
                    id: "1",
                    postId: "post1",
                    userId: "user1",
                    username: "Test Kullanıcı",
                    content: "Bu bir örnek yorum içeriğidir. Yorumlar bu şekilde görüntülenecektir.",
                    timestamp: Date()
                )
            )
            .padding()
        }
        .preferredColorScheme(.dark)
    }
} 
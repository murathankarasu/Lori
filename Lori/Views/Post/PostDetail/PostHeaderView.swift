import SwiftUI

struct PostHeaderView: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(post.username)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(post.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
} 
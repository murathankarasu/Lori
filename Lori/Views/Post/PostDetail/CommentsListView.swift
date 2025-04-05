import SwiftUI

struct CommentsListView: View {
    let comments: [Comment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Yorumlar")
                .font(.headline)
                .foregroundColor(.white)
            
            if comments.isEmpty {
                Text("Henüz yorum yapılmamış")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(comments) { comment in
                        CommentRowView(comment: comment)
                    }
                }
            }
        }
    }
} 
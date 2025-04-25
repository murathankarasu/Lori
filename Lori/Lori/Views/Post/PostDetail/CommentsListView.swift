import SwiftUI

struct CommentsListView: View {
    let comments: [Comment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Yorumlar")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if comments.isEmpty {
                Text("Henüz yorum yapılmamış")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(comments) { comment in
                        CommentRowView(comment: comment)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
} 
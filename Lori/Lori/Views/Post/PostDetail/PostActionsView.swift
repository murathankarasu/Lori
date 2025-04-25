import SwiftUI

struct PostActionsView: View {
    let post: Post
    let isLiked: Bool
    let likesCount: Int
    let commentsCount: Int
    let onLikeTapped: () -> Void
    let onCommentTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 24) {
            Button(action: onLikeTapped) {
                HStack(spacing: 8) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .white)
                        .imageScale(.large)
                    Text("\(likesCount)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            
            Button(action: onCommentTapped) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.white)
                        .imageScale(.large)
                    Text("\(commentsCount)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
} 
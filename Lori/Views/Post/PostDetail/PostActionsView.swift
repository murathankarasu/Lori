import SwiftUI

struct PostActionsView: View {
    let post: Post
    let isLiked: Bool
    let likesCount: Int
    let commentsCount: Int
    let viewCount: Int
    let onLikeTapped: () -> Void
    let onCommentTapped: () -> Void
    
    @State private var heartScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 24) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    heartScale = 1.3
                    onLikeTapped()
                    
                    // Animasyonu resetlemek için
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            heartScale = 1.0
                        }
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .white)
                        .imageScale(.large)
                        .scaleEffect(heartScale)
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
            
            // Görüntülenme sayısı
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.white)
                    .imageScale(.large)
                Text(formatViewCount(viewCount))
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func formatViewCount(_ count: Int) -> String {
        if count >= 10000 {
            let thousands = count / 1000
            return "\(thousands)k+"
        }
        return "\(count)"
    }
} 
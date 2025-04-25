import SwiftUI

struct PostContentView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(post.content)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            if let imageUrl = post.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(16)
                        }
                    }
                }
            }
        }
    }
} 
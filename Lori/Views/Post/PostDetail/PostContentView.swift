import SwiftUI
import Kingfisher

struct PostContentView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(post.content)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            if let imageUrl = post.imageUrl, let url = URL(string: imageUrl) {
                KFImage(url)
                    .placeholder {
                        ZStack {
                            Color.gray.opacity(0.3)
                            ProgressView()
                                .tint(.white)
                        }
                        .frame(height: 400)
                        .cornerRadius(16)
                    }
                    .retry(maxCount: 3, interval: .seconds(2))
                    .onFailure { error in
                        print("⚠️ Image loading failed: \(url) - Error: \(error.localizedDescription)")
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, minHeight: 250, maxHeight: 450)
                    .background(Color.black)
                    .cornerRadius(16)
                    .onAppear {
                        print("📸 Trying to load image from URL: \(url)")
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
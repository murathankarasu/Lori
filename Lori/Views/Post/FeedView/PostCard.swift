import SwiftUI

struct PostCard: View {
    let post: Post
    @State private var showComments = false
    @State private var isLiked = false
    
    var body: some View {
        Button(action: {
            showComments = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Kullanıcı bilgileri
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading) {
                        Text(post.username)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(post.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Tag'leri göster
                    if !post.tags.isEmpty {
                        Text(post.tags.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                // Gönderi içeriği
                Text(post.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .multilineTextAlignment(.leading)
                
                // Gönderi resmi (varsa)
                if let imageUrl = post.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
                
                // Etkileşim butonları
                HStack(spacing: 20) {
                    Button(action: {
                        isLiked.toggle()
                    }) {
                        HStack {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .white)
                            Text("\(post.likes)")
                                .foregroundColor(.white)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "bubble.right")
                            .foregroundColor(.white)
                        Text("\(post.comments.count)")
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Paylaşım işlemi
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showComments) {
            PostDetailView(post: post)
        }
    }
} 
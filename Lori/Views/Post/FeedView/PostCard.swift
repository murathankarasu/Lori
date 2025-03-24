import SwiftUI

struct PostCard: View {
    let post: Post
    @State private var showComments = false
    
    var body: some View {
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
            }
            .padding(.horizontal)
            
            // Gönderi içeriği
            Text(post.content)
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal)
            
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
            HStack {
                Button(action: {
                    // Beğeni işlemi
                }) {
                    HStack {
                        Image(systemName: "heart")
                        Text("\(post.likes)")
                    }
                    .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    showComments = true
                }) {
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments.count)")
                    }
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
        .sheet(isPresented: $showComments) {
            PostDetailView(post: post)
        }
    }
} 
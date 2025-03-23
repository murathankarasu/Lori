import SwiftUI
import FirebaseFirestore

struct PostView: View {
    let post: Post
    let isFollowing: Bool
    let onFollowTapped: (String) -> Void
    @State private var showSimilarPosts = false
    @State private var similarPosts: [Post] = []
    @State private var isLoadingSimilarPosts = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Kullanıcı bilgileri
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading) {
                    Text(post.username)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(post.timestamp.formatted())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if !isFollowing {
                    Button(action: { onFollowTapped(post.userId) }) {
                        Text("Takip Et")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                }
            }
            
            // Gönderi içeriği
            Text(post.content)
                .font(.body)
                .foregroundColor(.white)
                .padding(.vertical, 8)
            
            // Etiketler
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(post.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Benzer gönderiler
            if !post.similarPosts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { showSimilarPosts.toggle() }) {
                        HStack {
                            Text("Benzer Gönderiler")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Image(systemName: showSimilarPosts ? "chevron.up" : "chevron.down")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if showSimilarPosts {
                        if isLoadingSimilarPosts {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            ForEach(similarPosts) { similarPost in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                        
                                        VStack(alignment: .leading) {
                                            Text(similarPost.username)
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            Text(similarPost.timestamp.formatted())
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Text(similarPost.content)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .onAppear {
                    fetchSimilarPosts()
                }
            }
            
            // Beğeni butonu
            HStack {
                Button(action: {}) {
                    Image(systemName: "heart")
                        .foregroundColor(.white)
                }
                
                Text("\(post.likes)")
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private func fetchSimilarPosts() {
        isLoadingSimilarPosts = true
        let db = Firestore.firestore()
        
        db.collection("posts")
            .whereField(FieldPath.documentID(), in: post.similarPosts)
            .getDocuments { snapshot, error in
                isLoadingSimilarPosts = false
                
                if let error = error {
                    print("Benzer gönderiler alınırken hata: \(error.localizedDescription)")
                    return
                }
                
                similarPosts = snapshot?.documents.compactMap { document -> Post? in
                    let data = document.data()
                    guard let username = data["username"] as? String,
                          let content = data["content"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp,
                          let likes = data["likes"] as? Int,
                          let userId = data["userId"] as? String else { return nil }
                    
                    return Post(
                        id: document.documentID,
                        username: username,
                        content: content,
                        timestamp: timestamp.dateValue(),
                        likes: likes,
                        userId: userId,
                        tags: data["tags"] as? [String] ?? [],
                        isViewed: false,
                        similarPosts: data["similarPosts"] as? [String] ?? []
                    )
                } ?? []
            }
    }
} 
import SwiftUI
import FirebaseFirestore

struct FeaturedFeedView: View {
    @Binding var selectedPost: Post?
    @Binding var showPostDetail: Bool
    @State private var posts: [Post] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCreatePost = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Üst bar
                    HStack {
                        Spacer()
                        
                        Image("loginlogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        
                        Spacer()
                        
                        Button(action: { showCreatePost = true }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(posts) { post in
                                    PostCard(post: post)
                                        .onTapGesture {
                                            selectedPost = post
                                            showPostDetail = true
                                        }
                                }
                            }
                            .padding(.top)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreatePost) {
                CreatePostView()
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Hata"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("Tamam"))
                )
            }
            .onAppear {
                loadPosts()
            }
        }
    }
    
    private func loadPosts() {
        let db = Firestore.firestore()
        
        db.collection("posts")
            .whereField("isFeatured", isEqualTo: true)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "Gönderiler yüklenirken bir hata oluştu: \(error.localizedDescription)"
                    showError = true
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                posts = documents.compactMap { document -> Post? in
                    let data = document.data()
                    return Post(
                        id: document.documentID,
                        userId: data["userId"] as? String ?? "",
                        username: data["username"] as? String ?? "",
                        content: data["content"] as? String ?? "",
                        imageUrl: data["imageUrl"] as? String,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        likes: data["likes"] as? Int ?? 0,
                        comments: []
                    )
                }
            }
    }
} 
import SwiftUI
import FirebaseFirestore

struct FollowersView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @State private var followers: [User] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    List(followers) { user in
                        HStack {
                            AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.white)
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(user.username)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(user.bio)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Takipçiler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadFollowers()
        }
    }
    
    private func loadFollowers() {
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document,
               let followerIds = document.data()?["followers"] as? [String] {
                
                let group = DispatchGroup()
                var loadedFollowers: [User] = []
                
                for followerId in followerIds {
                    group.enter()
                    
                    db.collection("users").document(followerId).getDocument(completion: { document, error in
                        defer { group.leave() }
                        
                        if let document = document,
                           let data = document.data() {
                            let user = User(
                                id: document.documentID,
                                username: data["username"] as? String ?? "",
                                email: data["email"] as? String ?? "",
                                bio: data["bio"] as? String ?? "",
                                profileImageUrl: data["profileImageUrl"] as? String,
                                followers: data["followers"] as? [String] ?? [],
                                following: data["following"] as? [String] ?? []
                            )
                            loadedFollowers.append(user)
                        }
                    })
                }
                
                group.notify(queue: .main) {
                    followers = loadedFollowers
                    isLoading = false
                }
            }
        }
    }
} 
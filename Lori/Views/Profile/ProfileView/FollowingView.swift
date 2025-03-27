import SwiftUI
import FirebaseFirestore

struct FollowingView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @State private var following: [User] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    List(following) { user in
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
                                Text(user.bio ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Takip Edilenler")
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
            loadFollowing()
        }
    }
    
    private func loadFollowing() {
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document,
               let followingIds = document.data()?["following"] as? [String] {
                
                let group = DispatchGroup()
                var loadedFollowing: [User] = []
                
                for followingId in followingIds {
                    group.enter()
                    
                    db.collection("users").document(followingId).getDocument(completion: { document, error in
                        defer { group.leave() }
                        
                        if let document = document,
                           let data = document.data() {
                            let user = User(
                                id: document.documentID,
                                username: data["username"] as? String ?? "",
                                email: data["email"] as? String ?? "",
                                profileImageUrl: data["profileImageUrl"] as? String,
                                bio: data["bio"] as? String,
                                followers: (data["followers"] as? [String])?.count ?? 0,
                                following: (data["following"] as? [String])?.count ?? 0,
                                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                                isVerified: data["isVerified"] as? Bool ?? false
                            )
                            loadedFollowing.append(user)
                        }
                    })
                }
                
                group.notify(queue: .main) {
                    following = loadedFollowing
                    isLoading = false
                }
            }
        }
    }
} 

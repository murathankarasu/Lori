import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var user: User?
    @State private var posts: [Post] = []
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showFollowers = false
    @State private var showFollowing = false
    @State private var isEditingProfile = false
    @State private var bio = ""
    @State private var username = ""
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profil başlığı
                    VStack(spacing: 15) {
                        // Profil fotoğrafı
                        Button(action: { showImagePicker = true }) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.white)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            }
                        }
                        
                        // Kullanıcı bilgileri
                        VStack(spacing: 5) {
                            Text(username)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(bio)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Takipçi ve takip edilen sayıları
                        HStack(spacing: 40) {
                            Button(action: { showFollowers = true }) {
                                VStack {
                                    Text("\(user?.followers.count ?? 0)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("Takipçi")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Button(action: { showFollowing = true }) {
                                VStack {
                                    Text("\(user?.following.count ?? 0)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("Takip Edilen")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        // Profil düzenleme butonu
                        Button(action: { isEditingProfile = true }) {
                            Text("Profili Düzenle")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 200, height: 40)
                                .background(Color.blue)
                                .cornerRadius(20)
                        }
                    }
                    .padding()
                    
                    // Gönderiler
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 1) {
                        ForEach(posts) { post in
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
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .sheet(isPresented: $showFollowers) {
            FollowersView(userId: user?.id ?? "")
        }
        .sheet(isPresented: $showFollowing) {
            FollowingView(userId: user?.id ?? "")
        }
        .sheet(isPresented: $isEditingProfile) {
            EditProfileView(user: user, bio: $bio, username: $username, profileImage: $selectedImage)
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(currentUser.uid).getDocument { document, error in
            if let document = document,
               let data = document.data() {
                user = User(
                    id: document.documentID,
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    bio: data["bio"] as? String ?? "",
                    profileImageUrl: data["profileImageUrl"] as? String,
                    followers: data["followers"] as? [String] ?? [],
                    following: data["following"] as? [String] ?? []
                )
                
                username = user?.username ?? ""
                bio = user?.bio ?? ""
                
                if let imageUrl = user?.profileImageUrl {
                    // Profil fotoğrafını yükle
                    loadImage(from: imageUrl)
                }
                
                // Kullanıcının gönderilerini yükle
                loadUserPosts()
            }
        }
    }
    
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    selectedImage = image
                }
            }
        }.resume()
    }
    
    private func loadUserPosts() {
        guard let userId = user?.id else { return }
        let db = Firestore.firestore()
        
        db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
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
                            comments: [],
                            isViewed: false,
                            tags: []
                        )
                    }
                }
            }
    }
}

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
                    
                    db.collection("users").document(followerId).getDocument { document, error in
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
                    }
                }
                
                group.notify(queue: .main) {
                    followers = loadedFollowers
                    isLoading = false
                }
            }
        }
    }
}

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
                                Text(user.bio)
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
                    
                    db.collection("users").document(followingId).getDocument { document, error in
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
                            loadedFollowing.append(user)
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    following = loadedFollowing
                    isLoading = false
                }
            }
        }
    }
}

struct EditProfileView: View {
    let user: User?
    @Binding var bio: String
    @Binding var username: String
    @Binding var profileImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Profil fotoğrafı
                    Button(action: {}) {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.white)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                    }
                    
                    // Kullanıcı adı
                    TextField("Kullanıcı Adı", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // Bio
                    TextEditor(text: $bio)
                        .frame(height: 100)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Kaydet butonu
                    Button(action: saveProfile) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Kaydet")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(25)
                        }
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Bilgi"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Tamam")) {
                    if alertMessage.contains("başarıyla") {
                        dismiss()
                    }
                }
            )
        }
    }
    
    private func saveProfile() {
        guard let userId = user?.id else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        
        // Profil fotoğrafını yükle
        if let image = profileImage {
            // Firebase Storage'a fotoğraf yükleme işlemi burada yapılacak
            // Şimdilik örnek bir URL kullanıyoruz
            let imageUrl = "https://example.com/profile.jpg"
            
            // Kullanıcı bilgilerini güncelle
            db.collection("users").document(userId).updateData([
                "username": username,
                "bio": bio,
                "profileImageUrl": imageUrl
            ]) { error in
                isLoading = false
                
                if let error = error {
                    alertMessage = "Profil güncellenirken bir hata oluştu: \(error.localizedDescription)"
                } else {
                    alertMessage = "Profil başarıyla güncellendi!"
                }
                
                showAlert = true
            }
        } else {
            // Sadece metin bilgilerini güncelle
            db.collection("users").document(userId).updateData([
                "username": username,
                "bio": bio
            ]) { error in
                isLoading = false
                
                if let error = error {
                    alertMessage = "Profil güncellenirken bir hata oluştu: \(error.localizedDescription)"
                } else {
                    alertMessage = "Profil başarıyla güncellendi!"
                }
                
                showAlert = true
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
} 
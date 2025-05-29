import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import Kingfisher

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var username: String
    @Binding var bio: String
    @Binding var profileImageUrl: String?
    
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var tempBio: String
    @State private var tempUsername: String
    
    init(username: Binding<String>, bio: Binding<String>, profileImageUrl: Binding<String?>) {
        _username = username
        _bio = bio
        _profileImageUrl = profileImageUrl
        _tempBio = State(initialValue: bio.wrappedValue)
        _tempUsername = State(initialValue: username.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(.systemGray6).opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header spacer
                    Color.clear.frame(height: 20)
                    
                    // Profile Photo Section
                    VStack(spacing: 20) {
                        ZStack {
                            // Background circle with gradient
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 140, height: 140)
                            
                            // Profile image
                            Button(action: { showImagePicker = true }) {
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.white, Color.white.opacity(0.5)]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 3
                                                )
                                        )
                                } else if let imageUrl = profileImageUrl {
                                    KFImage(URL(string: imageUrl))
                                        .setProcessor(RoundCornerImageProcessor(cornerRadius: 60))
                                        .cacheMemoryOnly(false)
                                        .cacheOriginalImage()
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.white, Color.white.opacity(0.5)]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 3
                                                )
                                        )
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white.opacity(0.6))
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        )
                                }
                            }
                            
                            // Camera icon overlay
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button(action: { showImagePicker = true }) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black)
                                            .frame(width: 32, height: 32)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    }
                                    .offset(x: -8, y: -8)
                                }
                            }
                            .frame(width: 120, height: 120)
                        }
                        
                        Text("Tap to change photo")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Form Section
                    VStack(spacing: 24) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            TextField("Enter username", text: $tempUsername)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .accentColor(.white)
                        }
                        
                        // Bio Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Me")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            TextField("Tell us about yourself...", text: $tempBio, axis: .vertical)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .frame(minHeight: 100)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .accentColor(.white)
                                .lineLimit(4...8)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Bottom spacer
                    Color.clear.frame(height: 100)
                }
            }
            
            // Loading overlay
            if isLoading {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("Saving changes...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .disabled(isLoading)
                .opacity(isLoading ? 0.6 : 1.0)
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveChanges() {
        isLoading = true
        
        Task {
            do {
                // Profil resmini güncelle
                if let image = selectedImage {
                    guard let userId = Auth.auth().currentUser?.uid else {
                        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı oturumu bulunamadı"])
                    }
                    
                    guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Resim dönüştürülemedi"])
                    }
                    
                    // --- GÖRSEL ANALİZ ---
                    let analysisService = MediaAnalysisService()
                    let isSafe = try await analysisService.analyzeImageData(imageData, operationType: .profileImage)
                    if !isSafe {
                        await MainActor.run {
                            isLoading = false
                            showError = true
                            errorMessage = "Yüklediğiniz profil fotoğrafı topluluk kurallarına uygun değil. Lütfen başka bir fotoğraf seçin."
                        }
                        return
                    }
                    // --- GÖRSEL ANALİZ SONU ---
                    
                    let storage = Storage.storage()
                    let storageRef = storage.reference()
                        .child("profile_images")
                        .child("\(userId).jpg")
                    
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"
                    
                    print("Profil resmi yükleniyor: \(storageRef.fullPath)")
                    
                    _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
                    let downloadURL = try await storageRef.downloadURL()
                    
                    print("Profil resmi yüklendi: \(downloadURL.absoluteString)")
                    
                    // Firestore'da profil resmini güncelle
                    try await Firestore.firestore().collection("users").document(userId).updateData([
                        "profileImageUrl": downloadURL.absoluteString
                    ])
                    
                    profileImageUrl = downloadURL.absoluteString
                    
                    // Update profile image in all user's posts
                    do {
                        await updateProfileImageInPosts(newImageUrl: downloadURL.absoluteString, userId: userId)
                    } catch {
                        print("Warning: Failed to update profile image in posts: \(error.localizedDescription)")
                        // Continue execution even if post updates fail
                    }
                }
                
                // Biyografiyi güncelle
                if tempBio != bio {
                    try await Firestore.firestore().collection("users").document(Auth.auth().currentUser?.uid ?? "").updateData([
                        "bio": tempBio,
                    ])
                    bio = tempBio
                }
                
                // Kullanıcı adını güncelle
                if !tempUsername.isEmpty && tempUsername != username {
                    try await Firestore.firestore().collection("users").document(Auth.auth().currentUser?.uid ?? "").updateData([
                        "username": tempUsername,
                        "usernameLower": tempUsername.lowercased()
                    ])
                    username = tempUsername
                }
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    showError = true
                    errorMessage = error.localizedDescription
                    print("Hata: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateProfileImageInPosts(newImageUrl: String, userId: String) async {
        do {
            let db = Firestore.firestore()
            let batchSize = 500 // Firestore batch size limit
            
            // Get all posts by this user
            let postsRef = db.collection("posts").whereField("userId", isEqualTo: userId)
            let snapshot = try await postsRef.getDocuments()
            
            print("Updating profile image in \(snapshot.documents.count) posts")
            
            // Process in batches to avoid exceeding Firestore limits
            for i in stride(from: 0, to: snapshot.documents.count, by: batchSize) {
                let batch = db.batch()
                let endIdx = min(i + batchSize, snapshot.documents.count)
                
                for j in i..<endIdx {
                    let postDoc = snapshot.documents[j]
                    batch.updateData(["profileImageUrl": newImageUrl], forDocument: postDoc.reference)
                }
                
                try await batch.commit()
                print("Updated batch \(i/batchSize + 1) of posts")
            }
            
            print("Successfully updated profile image in all posts")
        } catch {
            print("Error updating profile image in posts: \(error.localizedDescription)")
        }
    }
}

#Preview {
    EditProfileView(
        username: .constant("username"),
        bio: .constant("bio"),
        profileImageUrl: .constant(nil)
    )
} 
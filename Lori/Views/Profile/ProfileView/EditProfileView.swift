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
    @Binding var interests: [String]
    @Binding var profileImageUrl: String?
    
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var tempBio: String
    @State private var showInterestPicker = false
    @State private var searchText = ""
    
    private let availableInterests = [
        Interest(name: "Teknoloji", icon: "laptopcomputer"),
        Interest(name: "Spor", icon: "sportscourt"),
        Interest(name: "Müzik", icon: "music.note"),
        Interest(name: "Sanat", icon: "paintpalette"),
        Interest(name: "Yemek", icon: "fork.knife"),
        Interest(name: "Seyahat", icon: "airplane"),
        Interest(name: "Kitap", icon: "book"),
        Interest(name: "Film", icon: "film"),
        Interest(name: "Oyun", icon: "gamecontroller"),
        Interest(name: "Bilim", icon: "atom")
    ].map { $0.name }
    
    private var filteredInterests: [String] {
        if searchText.isEmpty {
            return availableInterests
        } else {
            return availableInterests.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    init(username: Binding<String>, bio: Binding<String>, interests: Binding<[String]>, profileImageUrl: Binding<String?>) {
        _username = username
        _bio = bio
        _interests = interests
        _profileImageUrl = profileImageUrl
        _tempBio = State(initialValue: bio.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profil Resmi Bölümü
                    VStack(spacing: 12) {
                        Button(action: { showImagePicker = true }) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            } else if let imageUrl = profileImageUrl {
                                KFImage(URL(string: imageUrl))
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
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text("Fotoğrafı Değiştir")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 32)
                    
                    // Biyografi Bölümü
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Biyografi")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Kendinizden bahsedin...", text: $tempBio, axis: .vertical)
                            .lineLimit(4...6)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(8)
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal)
                    
                    // İlgi Alanları Bölümü
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("İlgi Alanları")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: { showInterestPicker = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                        }
                        
                        if !interests.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(interests, id: \.self) { interest in
                                        HStack(spacing: 4) {
                                            Text(interest)
                                                .font(.system(size: 14))
                                                .foregroundColor(.black)
                                            
                                            Button(action: {
                                                if let index = interests.firstIndex(of: interest) {
                                                    interests.remove(at: index)
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.black)
                                                    .font(.system(size: 14))
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            Text("Henüz ilgi alanı eklenmemiş")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if isLoading {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView("Kaydediliyor...")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
        .navigationTitle("Profili Düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("İptal") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Kaydet") {
                    saveChanges()
                }
                .foregroundColor(.white)
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .sheet(isPresented: $showInterestPicker) {
            NavigationView {
                VStack(spacing: 0) {
                    // Arama Çubuğu
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("İlgi alanı ara...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    
                    // İlgi Alanları Listesi
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(filteredInterests.filter { !interests.contains($0) }, id: \.self) { interest in
                                Button(action: {
                                    interests.append(interest)
                                }) {
                                    Text(interest)
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("İlgi Alanı Seç")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Tamam") {
                            showInterestPicker = false
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) {}
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
                }
                
                // Biyografi ve ilgi alanlarını güncelle
                if tempBio != bio || interests != interests {
                    try await Firestore.firestore().collection("users").document(Auth.auth().currentUser?.uid ?? "").updateData([
                        "bio": tempBio,
                        "interests": interests
                    ])
                    bio = tempBio
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
}

#Preview {
    NavigationView {
        EditProfileView(
            username: .constant("username"),
            bio: .constant("bio"),
            interests: .constant([]),
            profileImageUrl: .constant(nil)
        )
    }
} 
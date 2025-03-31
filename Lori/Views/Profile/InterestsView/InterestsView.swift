import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct InterestsView: View {
    @State private var selectedInterests: Set<Interest> = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var isCreatingUser = false
    @State private var showLoadingView = false
    @State private var shouldNavigateToFeed = false
    @State private var showExitAlert = false
    @Binding var isLoggedIn: Bool
    
    let username: String
    
    @State private var interests: [Interest] = [
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
    ]
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Üst bar
                    HStack {
                        Button(action: {
                            showExitAlert = true
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("İlgi Alanlarınızı Seçin")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Sağ tarafta boşluk bırakmak için
                        Color.clear
                            .frame(width: 30, height: 30)
                    }
                    .padding(.horizontal)
                    .padding(.top, 30)
                    
                    Text("En az 3 ilgi alanı seçin")
                        .foregroundColor(.gray)
                    
                    SearchBar(text: $searchText)
                        .onChange(of: searchText) { oldValue, newValue in
                            filterInterests(newValue)
                        }
                    
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            ForEach(interests) { interest in
                                InterestCell(
                                    interest: interest,
                                    isSelected: selectedInterests.contains(interest),
                                    action: {
                                        withAnimation(.spring()) {
                                            if selectedInterests.contains(interest) {
                                                selectedInterests.remove(interest)
                                            } else {
                                                selectedInterests.insert(interest)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    
                    Button(action: saveInterests) {
                        Text("Devam Et")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(selectedInterests.count >= 3 ? Color.white : Color.gray)
                            .cornerRadius(25)
                            .padding(.horizontal)
                    }
                    .disabled(selectedInterests.count < 3 || isCreatingUser)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Bilgi"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Tamam")) {
                    if alertMessage.contains("başarıyla") {
                        shouldNavigateToFeed = true
                    }
                }
            )
        }
        .alert("Çıkış Yap", isPresented: $showExitAlert) {
            Button("İptal", role: .cancel) { }
            Button("Çıkış Yap", role: .destructive) {
                do {
                    try Auth.auth().signOut()
                    isLoggedIn = false
                } catch {
                    alertMessage = "Çıkış yapılırken bir hata oluştu: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        } message: {
            Text("Çıkış yapmak istediğinizden emin misiniz?")
        }
        .onChange(of: shouldNavigateToFeed) { newValue in
            if newValue {
                isLoggedIn = true
            }
        }
    }
    
    private func saveInterests() {
        guard selectedInterests.count >= 3 else {
            alertMessage = "Lütfen en az 3 ilgi alanı seçin."
            showAlert = true
            return
        }
        
        isCreatingUser = true
        
        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "Kullanıcı oturumu bulunamadı."
            showAlert = true
            isCreatingUser = false
            return
        }
        
        let db = Firestore.firestore()
        let interests = selectedInterests.map { $0.name }
        
        Auth.auth().currentUser?.reload { error in
            if let error = error {
                alertMessage = "Kullanıcı bilgileri kontrol edilemedi: \(error.localizedDescription)"
                showAlert = true
                isCreatingUser = false
                return
            }
            
            guard let user = Auth.auth().currentUser, user.isEmailVerified else {
                alertMessage = "Lütfen önce e-posta adresinizi doğrulayın."
                showAlert = true
                isCreatingUser = false
                return
            }
            
            db.collection("users").document(userId).updateData([
                "interests": interests,
                "hasSelectedInitialInterests": true,
                "interestCounts": interests.reduce(into: [String: Int]()) { dict, interest in
                    dict[interest] = 1
                }
            ]) { error in
                isCreatingUser = false
                
                if let error = error {
                    alertMessage = "İlgi alanları kaydedilemedi: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                alertMessage = "İlgi alanlarınız başarıyla kaydedildi!"
                showAlert = true
                shouldNavigateToFeed = true
            }
        }
    }
    
    private func filterInterests(_ text: String) {
        if text.isEmpty {
            interests = [
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
            ]
        } else {
            interests = interests.filter { $0.name.lowercased().contains(text.lowercased()) }
        }
    }
}

struct InterestCell: View {
    let interest: Interest
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: interest.icon)
                    .font(.system(size: 30))
                Text(interest.name)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isSelected ? Color.white : Color(.systemGray6))
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
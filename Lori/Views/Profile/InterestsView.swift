import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Interest: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct InterestsView: View {
    @State private var selectedInterests: Set<Interest> = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    let interests: [Interest] = [
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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("İlgi Alanlarınızı Seçin")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 30)
                    
                    Text("En az 3 ilgi alanı seçin")
                        .foregroundColor(.gray)
                    
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
                                        if selectedInterests.contains(interest) {
                                            selectedInterests.remove(interest)
                                        } else {
                                            selectedInterests.insert(interest)
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
                    .disabled(selectedInterests.count < 3)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Bilgi"), message: Text(alertMessage), dismissButton: .default(Text("Tamam")))
        }
    }
    
    private func saveInterests() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        let interests = selectedInterests.map { $0.name }
        
        db.collection("users").document(userId).updateData([
            "interests": interests,
            "hasSelectedInitialInterests": true,
            "interestCounts": interests.reduce(into: [String: Int]()) { dict, interest in
                dict[interest] = 1
            }
        ]) { error in
            if let error = error {
                alertMessage = "Hata: \(error.localizedDescription)"
                showAlert = true
            } else {
                // İlgi alanları başarıyla kaydedildi, LoadingView'a geri dön
                presentationMode.wrappedValue.dismiss()
            }
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
    }
} 
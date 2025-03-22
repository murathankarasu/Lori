import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

// Yasaklı kelime modeli
struct BannedWord: Identifiable {
    let id = UUID()
    let word: String
    let category: String
}

// Yasaklı kelime servisi
class ContentFilterService {
    static let shared = ContentFilterService()
    private var bannedWords: [BannedWord] = []
    
    init() {
        loadBannedWords()
    }
    
    private func loadBannedWords() {
        guard let path = Bundle.main.path(forResource: "banned_words", ofType: "csv") else {
            print("CSV dosyası bulunamadı")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let rows = content.components(separatedBy: "\n").dropFirst() // Başlık satırını atla
            
            bannedWords = rows.compactMap { row in
                let columns = row.components(separatedBy: ",")
                guard columns.count >= 2 else { return nil }
                return BannedWord(word: columns[0].trimmingCharacters(in: .whitespacesAndNewlines),
                                category: columns[1].trimmingCharacters(in: .whitespacesAndNewlines))
            }
        } catch {
            print("CSV dosyası okunamadı: \(error)")
        }
    }
    
    func checkInappropriateContent(_ text: String) -> (isInappropriate: Bool, category: String?) {
        let lowercasedText = text.lowercased()
        
        for bannedWord in bannedWords {
            if lowercasedText.contains(bannedWord.word.lowercased()) {
                return (true, bannedWord.category)
            }
        }
        
        return (false, nil)
    }
}

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isCheckingUsername = false
    @State private var isUsernameAvailable = true
    @State private var isShowingVerification = false
    @State private var isAnimating = false
    @State private var containsInappropriateContent = false
    @State private var inappropriateCategory: String?
    @State private var usernameDebounceTimer: Timer?
    
    // Şifre gereksinimleri için state değişkenleri
    @State private var hasMinLength = false
    @State private var hasUpperCase = false
    @State private var hasLowerCase = false
    @State private var hasNumber = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 30) {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        Text("Kayıt Ol")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    
                    VStack(spacing: 20) {
                        VStack(spacing: 15) {
                            TextField("Kullanıcı Adı", text: $username)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.none)
                                .onChange(of: username) { newValue in
                                    usernameDebounceTimer?.invalidate()
                                    
                                    if !newValue.isEmpty {
                                        usernameDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                                            checkUsername(newValue)
                                        }
                                    } else {
                                        containsInappropriateContent = false
                                        inappropriateCategory = nil
                                    }
                                }
                            
                            if !username.isEmpty {
                                HStack {
                                    if isCheckingUsername {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: isUsernameAvailable && !containsInappropriateContent ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(isUsernameAvailable && !containsInappropriateContent ? .green : .red)
                                    }
                                    Text(getStatusMessage())
                                        .foregroundColor(isUsernameAvailable && !containsInappropriateContent ? .green : .red)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            SecureField("Şifre", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .onChange(of: password) { newValue in
                                    checkPasswordRequirements(password: newValue)
                                }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Şifre Gereksinimleri:")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                
                                HStack {
                                    Image(systemName: hasMinLength ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(hasMinLength ? .green : .gray)
                                    Text("En az 8 karakter")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                
                                HStack {
                                    Image(systemName: hasUpperCase ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(hasUpperCase ? .green : .gray)
                                    Text("En az bir büyük harf")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                
                                HStack {
                                    Image(systemName: hasLowerCase ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(hasLowerCase ? .green : .gray)
                                    Text("En az bir küçük harf")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                
                                HStack {
                                    Image(systemName: hasNumber ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(hasNumber ? .green : .gray)
                                    Text("En az bir rakam")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 5)
                            
                            SecureField("Şifre Tekrar", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text("Şifreler eşleşmiyor")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            signUp()
                        }) {
                            Text("Devam Et")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                        .padding(.horizontal)
                        .disabled(!isUsernameAvailable || password != confirmPassword || !isPasswordValid())
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
        .onDisappear {
            usernameDebounceTimer?.invalidate()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Bilgi"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
        .sheet(isPresented: $isShowingVerification) {
            EmailVerificationView(username: username, password: password)
        }
    }
    
    private func getStatusMessage() -> String {
        if containsInappropriateContent {
            if let category = inappropriateCategory {
                return "Bu kullanıcı adı uygunsuz içerik içeriyor: \(category)"
            }
            return "Bu kullanıcı adı uygunsuz içerik içeriyor"
        } else if !isUsernameAvailable {
            return "Bu kullanıcı adı zaten kullanılıyor"
        }
        return "Kullanıcı adı uygundur"
    }
    
    private func checkUsername(_ username: String) {
        isCheckingUsername = true
        
        // Boşluk kontrolü
        if username.contains(" ") {
            containsInappropriateContent = true
            inappropriateCategory = "Boşluk içeremez"
            isUsernameAvailable = false
            isCheckingUsername = false
            return
        }
        
        // Uygunsuz içerik kontrolü
        let (isInappropriate, category) = ContentFilterService.shared.checkInappropriateContent(username)
        containsInappropriateContent = isInappropriate
        inappropriateCategory = category
        
        // Eğer uygunsuz içerik yoksa, kullanılabilirlik kontrolü yap
        if !containsInappropriateContent {
            Task {
                await checkUsernameAvailability(username: username)
                isCheckingUsername = false
            }
        } else {
            isUsernameAvailable = false
            isCheckingUsername = false
        }
    }
    
    private func checkUsernameAvailability(username: String) async {
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("users").whereField("username", isEqualTo: username).getDocuments()
            isUsernameAvailable = snapshot.documents.isEmpty
        } catch {
            print("Error checking username: \(error)")
            isUsernameAvailable = false
        }
    }
    
    private func checkPasswordRequirements(password: String) {
        hasMinLength = password.count >= 8
        hasUpperCase = password.contains(where: { $0.isUppercase })
        hasLowerCase = password.contains(where: { $0.isLowercase })
        hasNumber = password.contains(where: { $0.isNumber })
    }
    
    private func isPasswordValid() -> Bool {
        return hasMinLength && hasUpperCase && hasLowerCase && hasNumber
    }
    
    private func signUp() {
        guard !username.isEmpty, !password.isEmpty else {
            alertMessage = "Lütfen tüm alanları doldurun."
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Şifreler eşleşmiyor."
            showAlert = true
            return
        }
        
        guard isUsernameAvailable else {
            alertMessage = "Bu kullanıcı adı zaten kullanılıyor."
            showAlert = true
            return
        }
        
        guard !containsInappropriateContent else {
            if let category = inappropriateCategory {
                alertMessage = "Bu kullanıcı adı uygunsuz içerik içeriyor: \(category)"
            } else {
                alertMessage = "Bu kullanıcı adı uygunsuz içerik içeriyor."
            }
            showAlert = true
            return
        }
        
        isShowingVerification = true
    }
} 

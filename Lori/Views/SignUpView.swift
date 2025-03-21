import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isUsernameAvailable = true
    @State private var isAnimating = false
    @State private var isCheckingUsername = false
    @State private var isShowingVerification = false
    
    // Şifre gereksinimleri için state değişkenleri
    @State private var hasMinLength = false
    @State private var hasUpperCase = false
    @State private var hasLowerCase = false
    @State private var hasNumber = false
    @State private var hasSpecialChar = false
    
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
                        Text("Yeni Hesap Oluştur")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    
                    VStack(spacing: 20) {
                        VStack(spacing: 15) {
                            TextField("Kullanıcı Adı", text: $username)
                                .textFieldStyle(CustomTextFieldStyle())
                                .onChange(of: username) { newValue in
                                    checkUsernameAvailability(username: newValue)
                                }
                            
                            if !username.isEmpty {
                                HStack {
                                    if isCheckingUsername {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: isUsernameAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(isUsernameAvailable ? .green : .red)
                                    }
                                    Text(isUsernameAvailable ? "Kullanıcı adı uygundur" : "Bu kullanıcı adı zaten kullanılıyor")
                                        .foregroundColor(isUsernameAvailable ? .green : .red)
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
                                
                                HStack {
                                    Image(systemName: hasSpecialChar ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(hasSpecialChar ? .green : .gray)
                                    Text("En az bir özel karakter (!@#$%^&*)")
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
                            Text("Kayıt Ol")
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
    
    private func checkUsernameAvailability(username: String) {
        isCheckingUsername = true
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            isCheckingUsername = false
            if let error = error {
                print("Error checking username: \(error)")
                return
            }
            
            isUsernameAvailable = snapshot?.documents.isEmpty ?? true
        }
    }
    
    private func checkPasswordRequirements(password: String) {
        hasMinLength = password.count >= 8
        hasUpperCase = password.contains(where: { $0.isUppercase })
        hasLowerCase = password.contains(where: { $0.isLowercase })
        hasNumber = password.contains(where: { $0.isNumber })
        hasSpecialChar = password.contains(where: { "!@#$%^&*".contains($0) })
    }
    
    private func isPasswordValid() -> Bool {
        return hasMinLength && hasUpperCase && hasLowerCase && hasNumber && hasSpecialChar
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
        
        isShowingVerification = true
    }
} 

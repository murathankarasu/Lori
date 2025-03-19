import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isUsernameAvailable = true
    @State private var isAnimating = false
    @State private var isCheckingUsername = false
    @State private var isShowingVerification = false
    
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
                            }
                            
                            TextField("E-posta", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            SecureField("Şifre", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            SecureField("Şifre Tekrar", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Şifreler eşleşmiyor")
                                    .foregroundColor(.red)
                                    .font(.caption)
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
                        .disabled(!isUsernameAvailable || password != confirmPassword)
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
            EmailVerificationView(email: email, username: username, password: password)
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
    
    private func signUp() {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
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
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                return
            }
            
            if let user = result?.user {
                user.sendEmailVerification { error in
                    if let error = error {
                        alertMessage = error.localizedDescription
                        showAlert = true
                        return
                    }
                    isShowingVerification = true
                }
            }
        }
    }
} 

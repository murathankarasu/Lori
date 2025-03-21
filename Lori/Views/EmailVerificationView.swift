import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EmailVerificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isVerifying = false
    @State private var isVerified = false
    @State private var email = ""
    @State private var username: String
    @State private var password: String
    @State private var timer: Timer?
    @State private var timeRemaining = 60
    @State private var opacity: Double = 0.0
    @State private var showEmailSuggestions = false
    @State private var emailSuggestions: [String] = []
    
    private let commonEmailDomains = [
        "@gmail.com",
        "@outlook.com",
        "@icloud.com",
    ]
    
    init(username: String, password: String) {
        self._username = State(initialValue: username)
        self._password = State(initialValue: password)
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
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
                    
                    Text("E-posta Doğrulama")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                
                VStack(spacing: 20) {
                    Text("E-posta Doğrulama")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack {
                        TextField("E-posta", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal)
                            .onChange(of: email) { newValue in
                                updateEmailSuggestions(email: newValue)
                            }
                        
                        if showEmailSuggestions && !emailSuggestions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(emailSuggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            email = suggestion
                                            showEmailSuggestions = false
                                        }) {
                                            Text(suggestion)
                                                .foregroundColor(.white)
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 50)
                        }
                    }
                    
                    Text("E-posta adresinize gönderilen doğrulama bağlantısına tıklayınız")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .opacity(opacity)
                
                VStack(spacing: 15) {
                    if isVerifying {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    if isVerified {
                        Text("E-posta doğrulandı!")
                            .foregroundColor(.green)
                            .padding()
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    if isVerified {
                        checkVerification()
                    } else {
                        createUser()
                    }
                }) {
                    Text(isVerified ? "Doğrulamayı Kontrol Et" : "Kayıt Ol")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                .disabled(isVerifying || (!isVerified && email.isEmpty))
                
                if isVerified {
                    Button(action: {
                        resendCode()
                    }) {
                        Text(timeRemaining > 0 ? "Kodu Tekrar Gönder (\(timeRemaining)s)" : "Kodu Tekrar Gönder")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .disabled(isVerifying || timeRemaining > 0)
                }
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Bilgi"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
    
    private func updateEmailSuggestions(email: String) {
        let components = email.split(separator: "@")
        if components.count == 1 {
            let localPart = String(components[0])
            if !localPart.isEmpty {
                emailSuggestions = commonEmailDomains.map { localPart + $0 }
                showEmailSuggestions = true
            } else {
                emailSuggestions = []
                showEmailSuggestions = false
            }
        } else {
            emailSuggestions = []
            showEmailSuggestions = false
        }
    }
    
    private func startTimer() {
        timeRemaining = 60
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func createUser() {
        guard !email.isEmpty else {
            alertMessage = "Lütfen e-posta adresinizi girin."
            showAlert = true
            return
        }
        
        isVerifying = true
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                isVerifying = false
                return
            }
            
            if let user = result?.user {
                user.sendEmailVerification { error in
                    if let error = error {
                        alertMessage = error.localizedDescription
                        showAlert = true
                    } else {
                        isVerified = true
                        alertMessage = "Doğrulama bağlantısı gönderildi. Lütfen e-postanızı kontrol edin."
                        showAlert = true
                    }
                    isVerifying = false
                }
            }
        }
    }
    
    private func checkVerification() {
        isVerifying = true
        
        Auth.auth().currentUser?.reload { error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
                isVerifying = false
                return
            }
            
            if let user = Auth.auth().currentUser {
                if user.isEmailVerified {
                    // Kullanıcı bilgilerini Firestore'a kaydet
                    let db = Firestore.firestore()
                    db.collection("users").document(user.uid).setData([
                        "username": username,
                        "email": email,
                        "createdAt": FieldValue.serverTimestamp()
                    ]) { error in
                        if let error = error {
                            alertMessage = error.localizedDescription
                            showAlert = true
                        } else {
                            alertMessage = "Hesabınız başarıyla oluşturuldu!"
                            showAlert = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        isVerifying = false
                    }
                } else {
                    alertMessage = "Lütfen e-postanıza gönderilen doğrulama bağlantısına tıklayın."
                    showAlert = true
                    isVerifying = false
                }
            }
        }
    }
    
    private func resendCode() {
        Auth.auth().currentUser?.sendEmailVerification { error in
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                alertMessage = "Doğrulama bağlantısı tekrar gönderildi."
                showAlert = true
                startTimer()
            }
        }
    }
} 

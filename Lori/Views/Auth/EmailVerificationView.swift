import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EmailVerificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isVerifying = false
    @State private var email = ""
    @State private var username: String
    @State private var password: String
    @State private var timer: Timer?
    @State private var timeRemaining = 60
    @State private var opacity: Double = 0.0
    @State private var showEmailSuggestions = false
    @State private var emailSuggestions: [String] = []
    @State private var shouldDismissToLogin = false
    @State private var verificationStatus: VerificationStatus = .initial
    
    enum VerificationStatus {
        case initial
        case codeSent
        case verified
        
        var buttonText: String {
            switch self {
            case .initial:
                return "Kayıt Ol"
            case .codeSent:
                return "Doğrulamayı Kontrol Et"
            case .verified:
                return "Devam Et"
            }
        }
    }
    
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
                                .disabled(verificationStatus == .codeSent || verificationStatus == .verified)
                            
                            if showEmailSuggestions && !emailSuggestions.isEmpty && verificationStatus == .initial {
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
                        
                        if verificationStatus == .codeSent {
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.gray)
                                Text("E-posta adresinize gönderilen doğrulama bağlantısına tıklayın")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            .padding(.top, 10)
                        }
                    }
                    .opacity(opacity)
                    
                    VStack(spacing: 15) {
                        if isVerifying {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 15) {
                        if verificationStatus == .initial {
                            Button(action: createUser) {
                                Text("Kodu Gönder")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            .disabled(isVerifying || email.isEmpty)
                            
                            Button(action: checkVerification) {
                                Text("Kontrol Et")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .cornerRadius(25)
                            }
                            .padding(.horizontal)
                            .disabled(isVerifying || email.isEmpty)
                        }
                        
                        if verificationStatus == .codeSent {
                            Button(action: checkVerification) {
                                Text("Kontrol Et")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .cornerRadius(25)
                            }
                            .padding(.horizontal)
                            .disabled(isVerifying)
                            
                            Button(action: resendCode) {
                                Text(timeRemaining > 0 ? "Kodu Tekrar Gönder (\(timeRemaining)s)" : "Kodu Tekrar Gönder")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                            .disabled(isVerifying || timeRemaining > 0)
                        }
                        
                        if verificationStatus == .verified {
                            Button(action: {
                                shouldDismissToLogin = true
                                alertMessage = "Hesabınız başarıyla oluşturuldu!\nGiriş yapabilirsiniz."
                                showAlert = true
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
                            .disabled(isVerifying)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Bilgi"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Tamam")) {
                    if shouldDismissToLogin {
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(name: NSNotification.Name("DismissSignUp"), object: nil)
                        }
                    }
                }
            )
        }
    }
    
    private var statusMessage: String {
        switch verificationStatus {
        case .initial:
            return "Lütfen e-posta adresinizi giriniz"
        case .codeSent:
            return "E-posta adresinize\ngönderilen doğrulama\nbağlantısına tıklayınız"
        case .verified:
            return "E-posta adresiniz doğrulandı!"
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
    
    private func createUser() {
        guard !email.isEmpty else {
            alertMessage = "Lütfen e-posta adresinizi girin."
            showAlert = true
            return
        }
        
        isVerifying = true
        
        // Önce e-posta adresinin kullanımda olup olmadığını kontrol et
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                alertMessage = "E-posta kontrolü sırasında bir hata oluştu: \(error.localizedDescription)"
                showAlert = true
                isVerifying = false
                return
            }
            
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                alertMessage = "Bu e-posta adresi zaten kullanımda."
                showAlert = true
                isVerifying = false
                return
            }
            
            // E-posta kullanımda değilse kullanıcıyı oluştur
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    alertMessage = error.localizedDescription
                    showAlert = true
                    isVerifying = false
                    return
                }
                
                if let user = result?.user {
                    // Email doğrulama maili gönder
                    user.sendEmailVerification { error in
                        if let error = error {
                            // Hata durumunda kullanıcıyı sil
                            user.delete { _ in
                                alertMessage = error.localizedDescription
                                showAlert = true
                            }
                        } else {
                            verificationStatus = .codeSent
                            alertMessage = "Doğrulama bağlantısı gönderildi.\nLütfen e-postanızı kontrol edin."
                            showAlert = true
                            startTimer()
                        }
                        isVerifying = false
                    }
                }
            }
        }
    }
    
    private func checkVerification() {
        isVerifying = true
        
        if let user = Auth.auth().currentUser {
            user.reload { error in
                if let error = error {
                    alertMessage = error.localizedDescription
                    showAlert = true
                    isVerifying = false
                    return
                }
                
                if user.isEmailVerified {
                    // Email doğrulandıktan sonra Firestore'a kaydet
                    let db = Firestore.firestore()
                    let userData: [String: Any] = [
                        "username": username,
                        "email": email,
                        "uid": user.uid,
                        "createdAt": FieldValue.serverTimestamp()
                    ]
                    
                    db.collection("users").document(user.uid).setData(userData) { error in
                        if let error = error {
                            // Firestore'a kayıt başarısız olursa Authentication'dan da sil
                            user.delete { _ in
                                alertMessage = "Kullanıcı bilgileri kaydedilemedi: \(error.localizedDescription)"
                                showAlert = true
                            }
                            isVerifying = false
                            return
                        }
                        
                        verificationStatus = .verified
                        alertMessage = "E-posta adresiniz doğrulandı!\nDevam etmek için butona tıklayın."
                        showAlert = true
                        isVerifying = false
                    }
                } else {
                    alertMessage = "Lütfen e-postanıza gönderilen\ndoğrulama bağlantısına tıklayın."
                    showAlert = true
                    isVerifying = false
                }
            }
        } else {
            alertMessage = "Kullanıcı oturumu bulunamadı."
            showAlert = true
            isVerifying = false
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

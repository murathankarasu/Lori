import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class EmailVerificationViewModel: ObservableObject {
    @Published var email = ""
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var isVerifying = false
    @Published var verificationStatus: VerificationStatus = .initial
    @Published var showEmailSuggestions = false
    @Published var emailSuggestions: [String] = []
    @Published var shouldDismissToLogin = false
    @Published var timeRemaining = 60
    
    private var timer: Timer?
    private let username: String
    private let password: String
    
    let commonEmailDomains = [
        "@gmail.com",
        "@outlook.com",
        "@icloud.com",
    ]
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func updateEmailSuggestions(email: String) {
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
    
    func createUser() {
        guard !email.isEmpty else {
            alertMessage = "Lütfen e-posta adresinizi girin."
            showAlert = true
            return
        }
        
        isVerifying = true
        
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.alertMessage = "E-posta kontrolü sırasında bir hata oluştu: \(error.localizedDescription)"
                self.showAlert = true
                self.isVerifying = false
                return
            }
            
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                self.alertMessage = "Bu e-posta adresi zaten kullanımda."
                self.showAlert = true
                self.isVerifying = false
                return
            }
            
            Auth.auth().createUser(withEmail: self.email, password: self.password) { result, error in
                if let error = error {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    self.isVerifying = false
                    return
                }
                
                if let user = result?.user {
                    user.sendEmailVerification { error in
                        if let error = error {
                            user.delete { _ in
                                self.alertMessage = error.localizedDescription
                                self.showAlert = true
                            }
                        } else {
                            self.verificationStatus = .codeSent
                            self.alertMessage = "Doğrulama bağlantısı gönderildi.\nLütfen e-postanızı kontrol edin."
                            self.showAlert = true
                            self.startTimer()
                        }
                        self.isVerifying = false
                    }
                }
            }
        }
    }
    
    func checkVerification() {
        isVerifying = true
        
        if let user = Auth.auth().currentUser {
            user.reload { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    self.isVerifying = false
                    return
                }
                
                if user.isEmailVerified {
                    let db = Firestore.firestore()
                    let userData: [String: Any] = [
                        "username": self.username,
                        "email": self.email,
                        "uid": user.uid,
                        "createdAt": FieldValue.serverTimestamp()
                    ]
                    
                    db.collection("users").document(user.uid).setData(userData) { error in
                        if let error = error {
                            user.delete { _ in
                                self.alertMessage = "Kullanıcı bilgileri kaydedilemedi: \(error.localizedDescription)"
                                self.showAlert = true
                            }
                            self.isVerifying = false
                            return
                        }
                        
                        self.verificationStatus = .verified
                        self.alertMessage = "E-posta adresiniz doğrulandı!\nDevam etmek için butona tıklayın."
                        self.showAlert = true
                        self.isVerifying = false
                    }
                } else {
                    self.alertMessage = "Lütfen e-postanıza gönderilen\ndoğrulama bağlantısına tıklayın."
                    self.showAlert = true
                    self.isVerifying = false
                }
            }
        } else {
            alertMessage = "Kullanıcı oturumu bulunamadı."
            showAlert = true
            isVerifying = false
        }
    }
    
    func startTimer() {
        timeRemaining = 60
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }
    
    func resendCode() {
        Auth.auth().currentUser?.sendEmailVerification { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.alertMessage = error.localizedDescription
                self.showAlert = true
            } else {
                self.alertMessage = "Doğrulama bağlantısı tekrar gönderildi."
                self.showAlert = true
                self.startTimer()
            }
        }
    }
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
    }
} 
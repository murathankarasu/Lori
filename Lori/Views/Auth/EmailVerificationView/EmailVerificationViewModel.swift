import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import os.log

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
    @Published var showVerificationCheck = false
    @Published var isEmailVerified = false
    @Published var isNetworkError = false
    @Published var retryCount = 0
    
    private var timer: Timer?
    private let username: String
    private let password: String
    private let logger = Logger(subsystem: "com.lorien.app", category: "EmailVerification")
    private let maxRetries = 3
    
    let commonEmailDomains = [
        "@gmail.com",
        "@outlook.com",
        "@icloud.com",
    ]
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
        logger.info("EmailVerificationViewModel initialized for username: \(username)")
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
    
    func sendVerificationEmail() {
        guard !email.isEmpty else {
            logger.error("Email is empty")
            alertMessage = "Please enter your email address."
            showAlert = true
            return
        }
        
        isVerifying = true
        isNetworkError = false
        retryCount = 0
        logger.info("Starting email verification process for: \(self.email)")
        
        checkEmailAndSendVerification()
    }
    
    private func checkEmailAndSendVerification() {
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: self.email).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Error checking email existence: \(error.localizedDescription)")
                self.handleError(error)
                return
            }
            
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                self.logger.error("Email already in use: \(self.email)")
                self.alertMessage = "This email address is already in use."
                self.showAlert = true
                self.isVerifying = false
                return
            }
            
            self.createUserAndSendVerification()
        }
    }
    
    private func createUserAndSendVerification() {
        Auth.auth().createUser(withEmail: self.email, password: self.password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Error creating user: \(error.localizedDescription)")
                self.handleError(error)
                return
            }
            
            if let user = result?.user {
                self.sendVerificationEmailToUser(user)
            }
        }
    }
    
    private func sendVerificationEmailToUser(_ user: FirebaseAuth.User) {
        user.sendEmailVerification { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Error sending verification email: \(error.localizedDescription)")
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    self.logger.info("Retrying verification email send. Attempt \(self.retryCount)")
                    self.sendVerificationEmailToUser(user)
                } else {
                    user.delete { _ in
                        self.handleError(error)
                    }
                }
            } else {
                self.logger.info("Verification email sent successfully to: \(self.email)")
                self.verificationStatus = .codeSent
                self.showVerificationCheck = true
                self.alertMessage = "Verification email has been sent.\nPlease check your email and click the verification link."
                self.showAlert = true
                self.startTimer()
                self.shouldDismissToLogin = false
                self.isVerifying = false
            }
        }
    }
    
    func checkVerificationStatus() {
        isVerifying = true
        isNetworkError = false
        retryCount = 0
        logger.info("Checking verification status for email: \(self.email)")
        
        if let user = Auth.auth().currentUser {
            checkUserVerificationStatus(user)
        } else {
            logger.error("No current user found")
            alertMessage = "No user session found."
            showAlert = true
            isVerifying = false
        }
    }
    
    private func checkUserVerificationStatus(_ user: FirebaseAuth.User) {
        user.reload { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Error reloading user: \(error.localizedDescription)")
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    self.logger.info("Retrying verification check. Attempt \(self.retryCount)")
                    self.checkUserVerificationStatus(user)
                } else {
                    self.handleError(error)
                }
                return
            }
            
            if user.isEmailVerified {
                self.saveUserData(user)
            } else {
                self.logger.error("Email not verified for: \(self.email)")
                self.alertMessage = "Please click the verification link in your email."
                self.showAlert = true
                self.isVerifying = false
            }
        }
    }
    
    private func saveUserData(_ user: FirebaseAuth.User) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "username": self.username,
            "usernameLower": self.username.lowercased(),
            "email": self.email,
            "uid": user.uid,
            "createdAt": FieldValue.serverTimestamp(),
            "isEmailVerified": true,
            "lastLoginAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(user.uid).setData(userData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Error saving user data: \(error.localizedDescription)")
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    self.logger.info("Retrying user data save. Attempt \(self.retryCount)")
                    self.saveUserData(user)
                } else {
                    user.delete { _ in
                        self.handleError(error)
                    }
                }
                return
            }
            
            self.logger.info("User data saved successfully for: \(self.username)")
            self.verificationStatus = .verified
            self.isEmailVerified = true
            self.alertMessage = "Email verified successfully!\nClick continue to sign in."
            self.showAlert = true
            self.shouldDismissToLogin = true
            self.isVerifying = false
            
            self.signInUser()
        }
    }
    
    private func signInUser() {
        Auth.auth().signIn(withEmail: self.email, password: self.password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Error signing in after verification: \(error.localizedDescription)")
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    self.logger.info("Retrying sign in. Attempt \(self.retryCount)")
                    self.signInUser()
                } else {
                    self.handleError(error)
                }
            } else {
                self.logger.info("User signed in successfully after verification")
            }
        }
    }
    
    private func handleError(_ error: Error) {
        let nsError = error as NSError
        
        if nsError.domain == NSURLErrorDomain {
            isNetworkError = true
            if self.retryCount < self.maxRetries {
                self.retryCount += 1
                logger.info("Retrying operation. Attempt \(self.retryCount)")
                return
            }
            alertMessage = "Network error. Please check your internet connection and try again."
        } else if nsError.domain == "com.google.app_check_core" {
            alertMessage = "Please try again. If the problem persists, contact support."
        } else {
            alertMessage = error.localizedDescription
        }
        
        showAlert = true
        isVerifying = false
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
    
    func resendVerificationEmail() {
        logger.info("Resending verification email to: \(self.email)")
        isNetworkError = false
        retryCount = 0
        Auth.auth().currentUser?.sendEmailVerification { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.logger.error("Error resending verification email: \(error.localizedDescription)")
                if self.retryCount < self.maxRetries {
                    self.retryCount += 1
                    self.logger.info("Retrying email resend. Attempt \(self.retryCount)")
                    self.resendVerificationEmail()
                } else {
                    self.handleError(error)
                }
            } else {
                self.logger.info("Verification email resent successfully")
                self.alertMessage = "Verification email has been resent."
                self.showAlert = true
                self.startTimer()
            }
        }
    }
    
    func cleanup() {
        timer?.invalidate()
        timer = nil
        logger.info("EmailVerificationViewModel cleanup completed")
    }
} 
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EmailVerificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isVerifying = false
    @State private var isVerified = false
    @State private var email: String
    @State private var username: String
    @State private var password: String
    @State private var timer: Timer?
    @State private var timeRemaining = 60
    @State private var opacity: Double = 0.0
    
    init(email: String, username: String, password: String) {
        self._email = State(initialValue: email)
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
                    
                    Text("\(email) adresine gönderilen doğrulama bağlantısına tıklayınız")
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
                    checkVerification()
                }) {
                    Text("Doğrulamayı Kontrol Et")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                .disabled(isVerifying)
                
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
                    isVerified = true
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
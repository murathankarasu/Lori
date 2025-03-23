import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSending = false
    @State private var opacity: Double = 0.0
    @State private var showEmailSuggestions = false
    @State private var emailSuggestions: [String] = []
    
    private let commonEmailDomains = [
        "@gmail.com",
        "@outlook.com",
        "@icloud.com",
    ]
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Üst kısım - Geri dönüş butonu ve başlık
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Text("Şifre Sıfırlama")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                
                VStack(spacing: 20) {
                    Text("Şifrenizi Sıfırlayın")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
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
                }
                .opacity(opacity)
                
                if isSending {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                Spacer()
                
                Button(action: {
                    resetPassword()
                }) {
                    Text("Şifre Sıfırlama Bağlantısı Gönder")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                .disabled(isSending || email.isEmpty)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }
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
    
    private func resetPassword() {
        guard !email.isEmpty else {
            alertMessage = "Lütfen e-posta adresinizi girin."
            showAlert = true
            return
        }
        
        isSending = true
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isSending = false
            if let error = error {
                alertMessage = error.localizedDescription
                showAlert = true
            } else {
                alertMessage = "Şifre sıfırlama bağlantısı gönderildi. Lütfen e-postanızı kontrol edin."
                showAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
} 
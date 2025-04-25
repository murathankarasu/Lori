import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EmailVerificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: EmailVerificationViewModel
    @State private var opacity: Double = 0.0
    
    init(username: String, password: String) {
        _viewModel = StateObject(wrappedValue: EmailVerificationViewModel(username: username, password: password))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
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
                            EmailInputView(
                                email: $viewModel.email,
                                isDisabled: viewModel.verificationStatus == .codeSent || viewModel.verificationStatus == .verified,
                                onEmailChange: viewModel.updateEmailSuggestions
                            )
                            
                            if viewModel.showEmailSuggestions && !viewModel.emailSuggestions.isEmpty && viewModel.verificationStatus == .initial {
                                EmailSuggestionView(
                                    suggestions: viewModel.emailSuggestions,
                                    onSelect: { suggestion in
                                        viewModel.email = suggestion
                                        viewModel.showEmailSuggestions = false
                                    }
                                )
                            }
                        }
                        
                        if viewModel.verificationStatus == .codeSent {
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
                        if viewModel.isVerifying {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal)
                    
                    VerificationButtonsView(
                        status: viewModel.verificationStatus,
                        isVerifying: viewModel.isVerifying,
                        timeRemaining: viewModel.timeRemaining,
                        email: viewModel.email,
                        onCreateUser: viewModel.createUser,
                        onCheckVerification: viewModel.checkVerification,
                        onResendCode: viewModel.resendCode,
                        onContinue: {
                            viewModel.shouldDismissToLogin = true
                            viewModel.alertMessage = "Hesabınız başarıyla oluşturuldu!\nGiriş yapabilirsiniz."
                            viewModel.showAlert = true
                        }
                    )
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
            viewModel.cleanup()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Bilgi"),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("Tamam")) {
                    if viewModel.shouldDismissToLogin {
                        presentationMode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(name: NSNotification.Name("DismissSignUp"), object: nil)
                        }
                    }
                }
            )
        }
    }
} 
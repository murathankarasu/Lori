import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EmailVerificationView: View {
    @StateObject private var viewModel: EmailVerificationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    
    init(username: String, password: String) {
        _viewModel = StateObject(wrappedValue: EmailVerificationViewModel(username: username, password: password))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                // Header
                headerSection
                
                Spacer()
                
                // Main content
                if viewModel.verificationStatus == .initial {
                    emailInputSection
                } else if viewModel.showVerificationCheck {
                    verificationCheckSection
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    isAnimating = true
                }
            }
            
            // Loading overlay
            if viewModel.isVerifying {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Processing...")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .alert("Email Verification", isPresented: $viewModel.showAlert) {
            if viewModel.shouldDismissToLogin {
                Button("Continue") {
                    dismiss()
                }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Text("Email Verification")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.top, 50)
            
            // Elegant icon
            Image(systemName: "envelope.badge")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white)
                .opacity(0.9)
        }
    }
    
    private var emailInputSection: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Text("Verify Your Email")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Please enter your email address to complete the verification process and secure your account.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 16, weight: .regular))
                    .lineSpacing(4)
            }
            
            VStack(spacing: 20) {
                EmailInputView(
                    email: $viewModel.email,
                    isDisabled: viewModel.isVerifying,
                    onEmailChange: { email in
                        viewModel.updateEmailSuggestions(email: email)
                    }
                )
                
                if viewModel.showEmailSuggestions && !viewModel.emailSuggestions.isEmpty {
                    EmailSuggestionView(
                        suggestions: viewModel.emailSuggestions,
                        onSelect: { suggestion in
                            viewModel.email = suggestion
                            viewModel.showEmailSuggestions = false
                        }
                    )
                    .transition(.opacity.combined(with: .scale))
                }
            }
            
            Button(action: {
                viewModel.sendVerificationEmail()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Send Verification Email")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .cornerRadius(25)
            }
            .disabled(viewModel.isVerifying || viewModel.email.isEmpty)
            .opacity(viewModel.isVerifying || viewModel.email.isEmpty ? 0.6 : 1.0)
            .scaleEffect(viewModel.isVerifying ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isVerifying)
        }
    }
    
    private var verificationCheckSection: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                // Animated success icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.green)
                        .scaleEffect(viewModel.isVerifying ? 1.0 : 1.1)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.isVerifying)
                }
                
                VStack(spacing: 12) {
                    Text("Email Sent Successfully!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("We've sent a verification link to your email address. Please check your inbox and tap the link to verify your account.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 16, weight: .regular))
                        .lineSpacing(4)
                        .padding(.horizontal, 8)
                }
            }
            
            // Timer section
            if viewModel.timeRemaining > 0 {
                VStack(spacing: 8) {
                    Text("Automatic check in:")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("\(viewModel.timeRemaining)s")
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: {
                    viewModel.checkVerificationStatus()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Check Verification Status")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(25)
                }
                .disabled(viewModel.isVerifying)
                .opacity(viewModel.isVerifying ? 0.6 : 1.0)
                
                if viewModel.timeRemaining == 0 {
                    Button(action: {
                        viewModel.resendVerificationEmail()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("Resend Email")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(viewModel.isVerifying)
                    .opacity(viewModel.isVerifying ? 0.6 : 1.0)
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }
} 
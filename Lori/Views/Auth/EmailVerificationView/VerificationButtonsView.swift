import SwiftUI

struct VerificationButtonsView: View {
    let status: VerificationStatus
    let isVerifying: Bool
    let timeRemaining: Int
    let email: String
    let onCreateUser: () -> Void
    let onCheckVerification: () -> Void
    let onResendCode: () -> Void
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            if status == .initial {
                Button(action: onCreateUser) {
                    Text("Kodu Gönder")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .disabled(isVerifying || email.isEmpty)
                
                Button(action: onCheckVerification) {
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
            
            if status == .codeSent {
                Button(action: onCheckVerification) {
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
                
                Button(action: onResendCode) {
                    Text(timeRemaining > 0 ? "Kodu Tekrar Gönder (\(timeRemaining)s)" : "Kodu Tekrar Gönder")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .disabled(isVerifying || timeRemaining > 0)
            }
            
            if status == .verified {
                Button(action: onContinue) {
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
} 
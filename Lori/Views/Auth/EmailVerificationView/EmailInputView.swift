import SwiftUI

struct EmailInputView: View {
    @Binding var email: String
    let isDisabled: Bool
    let onEmailChange: (String) -> Void
    
    var body: some View {
        VStack {
            TextField("E-posta", text: $email)
                .textFieldStyle(EmailVerificationTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal)
                .onChange(of: email) { newValue in
                    onEmailChange(newValue)
                }
                .disabled(isDisabled)
        }
    }
} 
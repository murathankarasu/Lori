import SwiftUI

struct EmailInputView: View {
    @Binding var email: String
    let isDisabled: Bool
    let onEmailChange: (String) -> Void
    @State private var isEmailValid = false
    
    var body: some View {
        VStack {
            TextField("E-posta", text: $email)
                .textFieldStyle(EmailVerificationTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.horizontal)
                .onChange(of: email) { oldValue, newValue in
                    isEmailValid = newValue.contains("@") && newValue.contains(".")
                    onEmailChange(newValue)
                }
                .disabled(isDisabled)
        }
    }
} 
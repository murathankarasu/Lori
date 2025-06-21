import SwiftUI

struct EmailInputView: View {
    @Binding var email: String
    let isDisabled: Bool
    let onEmailChange: (String) -> Void
    @State private var isEmailValid = false
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Email address", text: $email)
                .textFieldStyle(CustomTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled(true)
                .foregroundColor(.white)
                .focused($isEmailFocused)
                .onChange(of: email) { oldValue, newValue in
                    // Simple email validation
                    isEmailValid = isValidEmail(newValue)
                    onEmailChange(newValue)
                }
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.6 : 1.0)
            
            // Email validation feedback
            if !email.isEmpty {
                HStack {
                    Image(systemName: isEmailValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isEmailValid ? .green : .red)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(isEmailValid ? "Valid email address" : "Please enter a valid email address")
                        .foregroundColor(isEmailValid ? .green : .red)
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.3), value: isEmailValid)
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
} 
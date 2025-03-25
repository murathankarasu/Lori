import SwiftUI

struct EmailVerificationTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .foregroundColor(.white)
    }
}

import SwiftUI

public struct CustomTextFieldStyle: TextFieldStyle {
    public init() {}
    
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(25)
            .foregroundColor(.white)
            .tint(.white)
    }
}

// Remove the unused EmailVerificationTextFieldStyle
// struct EmailVerificationTextFieldStyle: TextFieldStyle { ... }

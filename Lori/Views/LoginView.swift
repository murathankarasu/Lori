import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var isShowingSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image("loginlogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                
                Spacer()
                
                VStack(spacing: 20) {
                    VStack(spacing: 15) {
                        TextField("Kullanıcı Adı", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Şifre", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                    }) {
                        Text("Giriş Yap")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        isShowingSignUp = true
                    }) {
                        Text("Hesabın yok mu? Kayıt ol")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView()
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(25)
            .foregroundColor(.black)
            .tint(.black)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
} 

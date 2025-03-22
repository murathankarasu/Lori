import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var isShowingSignUp = false
    @State private var isShowingForgotPassword = false
    @State private var username = ""
    @State private var password = ""
    @State private var isAnimating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isLoggedIn = false
    @State private var showFeed = false
    @State private var showLoadingView = false
    
    var body: some View {
        NavigationView {
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
                            TextField("Kullanıcı Adı", text: $username)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.none)
                            
                            SecureField("Şifre", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            Task {
                                await loginUser()
                            }
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
                        
                        HStack {
                            Button(action: {
                                isShowingSignUp = true
                            }) {
                                Text("Hesabın yok mu? Kayıt ol")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                isShowingForgotPassword = true
                            }) {
                                Text("Şifremi Unuttum")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showFeed) {
                FeedView()
            }
            .fullScreenCover(isPresented: $showLoadingView) {
                LoadingView(isPresented: $showLoadingView) {
                    showFeed = true
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
            
            // SignUp'tan gelen bildirimi dinle
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("DismissSignUp"),
                object: nil,
                queue: .main) { _ in
                    isShowingSignUp = false
                }
        }
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $isShowingForgotPassword) {
            ForgotPasswordView()
        }
        .alert("Bilgi", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) {
                if isLoggedIn {
                    showLoadingView = true
                }
            }
        } message: {
            Text(alertMessage)
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
            }
        }
    }
    
    private func loginUser() async {
        guard !username.isEmpty, !password.isEmpty else {
            alertMessage = "Lütfen tüm alanları doldurun."
            showAlert = true
            return
        }
        
        isLoading = true
        
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("users")
                .whereField("username", isEqualTo: username)
                .getDocuments()
            
            guard let userDoc = snapshot.documents.first,
                  let email = userDoc.data()["email"] as? String else {
                alertMessage = "Kullanıcı adı veya şifre hatalı."
                showAlert = true
                isLoading = false
                return
            }
            
            do {
                let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
                
                if !authResult.user.isEmailVerified {
                    alertMessage = "Lütfen email adresinizi doğrulayın."
                    showAlert = true
                    isLoading = false
                    try? await Auth.auth().signOut()
                    return
                }
                
                isLoggedIn = true
                alertMessage = "Giriş başarılı!"
                showAlert = true
            } catch {
                alertMessage = "Kullanıcı adı veya şifre hatalı."
                showAlert = true
            }
        } catch {
            alertMessage = "Giriş yapılırken bir hata oluştu."
            showAlert = true
        }
        
        isLoading = false
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(25)
            .foregroundColor(.white)
            .tint(.white)
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

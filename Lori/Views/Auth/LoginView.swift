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
    @State private var showLoadingView = false
    @Binding var isLoggedIn: Bool
    
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
                        TextField("Username", text: $username)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        Task {
                            await loginUser()
                        }
                    }) {
                        Text("Sign In")
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
                            Text("Don't have an account? Sign Up")
                                .foregroundColor(.white)
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isShowingForgotPassword = true
                        }) {
                            Text("Forgot Password")
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
        .fullScreenCover(isPresented: $showLoadingView) {
            LoadingView(isPresented: $showLoadingView, isLoggedIn: $isLoggedIn, onFinish: {
                isLoggedIn = true
            }, username: username)
        }
        .fullScreenCover(isPresented: $isShowingSignUp) {
            SignUpView()
        }
        .fullScreenCover(isPresented: $isShowingForgotPassword) {
            ForgotPasswordView()
        }
        .alert("Information", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
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
            alertMessage = "Please fill in all fields."
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
                alertMessage = "Invalid username or password."
                showAlert = true
                isLoading = false
                return
            }
            
            do {
                let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
                let user = authResult.user
                
                try await user.reload()
                
                let currentUser = Auth.auth().currentUser
                if let isVerified = currentUser?.isEmailVerified, !isVerified {
                    print("Email verification status: \(isVerified)")
                    print("User UID: \(currentUser?.uid ?? "None")")
                    print("Email: \(currentUser?.email ?? "None")")
                    
                    alertMessage = "Please verify your email address."
                    showAlert = true
                    isLoading = false
                    try? await Auth.auth().signOut()
                    return
                }
                
                print("Login successful - UID: \(user.uid)")
                print("Email verified: \(user.isEmailVerified)")
                
                isLoading = false
                showLoadingView = true
                
            } catch {
                print("Login error: \(error.localizedDescription)")
                alertMessage = "Invalid username or password."
                showAlert = true
                isLoading = false
            }
        } catch {
            print("Firestore error: \(error.localizedDescription)")
            alertMessage = "An error occurred while signing in."
            showAlert = true
            isLoading = false
        }
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

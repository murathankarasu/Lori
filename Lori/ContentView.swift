//
//  ContentView.swift
//  Lori
//
//  Created by Murathan Karasu on 18.03.2025.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var authError: String? = nil
    @State private var isInitialized = false
    @State private var isLoading = true
    @State private var isEmailVerificationInProgress = false
    @State private var currentUser: FirebaseAuth.User?
    
    var body: some View {
        Group {
            if isLoading {
                // Yükleme ekranı
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    VStack(spacing: 20) {
                        Image("loginlogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
            } else if isLoggedIn {
                FeedView(isLoggedIn: $isLoggedIn)
                    .transition(.opacity)
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: isLoggedIn)
        .animation(.easeInOut, value: isLoading)
        .onAppear {
            checkInitialAuthState()
        }
        .alert("Hata", isPresented: .constant(authError != nil)) {
            Button("Tamam") {
                authError = nil
            }
        } message: {
            if let error = authError {
                Text(error)
            }
        }
    }
    
    private func checkInitialAuthState() {
        if let user = Auth.auth().currentUser {
            currentUser = user
            Task {
                do {
                    try await user.reload()
                    let isVerified = user.isEmailVerified
                    print("Kullanıcı durumu kontrol ediliyor:")
                    print("UID: \(user.uid)")
                    print("E-posta: \(user.email ?? "Yok")")
                    print("E-posta doğrulandı: \(isVerified)")
                    
                    await MainActor.run {
                        if isVerified {
                            isLoggedIn = true
                        } else {
                            isLoggedIn = false
                        }
                        isLoading = false
                    }
                } catch {
                    print("Kullanıcı bilgileri yenilenemedi: \(error.localizedDescription)")
                    await MainActor.run {
                        isLoggedIn = false
                        isLoading = false
                        authError = "Oturum durumu kontrol edilirken bir hata oluştu."
                    }
                }
            }
        } else {
            print("Kullanıcı oturumu bulunamadı")
            isLoggedIn = false
            isLoading = false
        }
        
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { _, user in
            if let user = user {
                print("Auth Listener - Kullanıcı durumu:")
                print("UID: \(user.uid)")
                print("E-posta: \(user.email ?? "Yok")")
                print("E-posta doğrulandı: \(user.isEmailVerified)")
                
                currentUser = user
                
                Task {
                    do {
                        try await user.reload()
                        let isVerified = user.isEmailVerified
                        
                        await MainActor.run {
                            withAnimation {
                                isLoggedIn = isVerified
                            }
                        }
                    } catch {
                        print("Kullanıcı bilgileri yenilenemedi: \(error.localizedDescription)")
                        await MainActor.run {
                            withAnimation {
                                isLoggedIn = false
                                authError = "Oturum durumu kontrol edilirken bir hata oluştu."
                            }
                        }
                    }
                }
            } else {
                print("Auth Listener - Kullanıcı oturumu yok")
                currentUser = nil
                withAnimation {
                    isLoggedIn = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

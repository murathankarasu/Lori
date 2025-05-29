//
//  ContentView.swift
//  Lorien
//
//  Created by Murathan on 23.05.2025.
//
import SwiftUI
import FirebaseAuth
import Kingfisher

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
            configureKingfisherCache()
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
        _ = Auth.auth().addStateDidChangeListener { _, user in
            if user != nil {
                isLoggedIn = true
            } else {
                isLoggedIn = false
            }
        }
    }
    
    private func configureKingfisherCache() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        cache.memoryStorage.config.countLimit = 50 // Maksimum 50 resim
        cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024 // 200 MB
        cache.diskStorage.config.expiration = .days(7) // 7 gün sakla
        
        // Temizleme politikasını ayarla
        ImageCache.default.clearDiskCache()
        ImageCache.default.clearMemoryCache()
        
        // Global processor'ı kaldırdık - artık her KFImage kendi stilini belirleyecek
        KingfisherManager.shared.defaultOptions = [
            .scaleFactor(UIScreen.main.scale),
            .cacheOriginalImage,
            .diskCacheExpiration(.days(7)),
            .memoryCacheExpiration(.days(1))
        ]
    }
}

#Preview {
    ContentView()
}

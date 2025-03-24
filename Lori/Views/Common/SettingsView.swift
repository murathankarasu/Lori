import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    @State private var showLogoutAlert = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSigningOut = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            if isSigningOut {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                Text("Çıkış Yap")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .disabled(isSigningOut)
                }
                
                Section("Hesap") {
                    NavigationLink {
                        Text("Profil Düzenle")
                    } label: {
                        Label("Profil Düzenle", systemImage: "person.crop.circle")
                    }
                    
                    NavigationLink {
                        Text("Bildirimler")
                    } label: {
                        Label("Bildirimler", systemImage: "bell")
                    }
                    
                    NavigationLink {
                        Text("Gizlilik")
                    } label: {
                        Label("Gizlilik", systemImage: "lock")
                    }
                }
                
                Section("Uygulama") {
                    NavigationLink {
                        Text("Hakkında")
                    } label: {
                        Label("Hakkında", systemImage: "info.circle")
                    }
                    
                    NavigationLink {
                        Text("Yardım")
                    } label: {
                        Label("Yardım", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Çıkış Yap", isPresented: $showLogoutAlert) {
                Button("İptal", role: .cancel) { }
                Button("Çıkış Yap", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Çıkış yapmak istediğinizden emin misiniz?")
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func signOut() {
        isSigningOut = true
        
        Task {
            do {
                // Önce kullanıcı oturumunu kapat
                try Auth.auth().signOut()
                
                // Sonra UI'ı güncelle ve login ekranına yönlendir
                await MainActor.run {
                    withAnimation {
                        isLoggedIn = false
                        isSigningOut = false
                        dismiss() // Mevcut view'ı kapat
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Çıkış yapılırken bir hata oluştu: \(error.localizedDescription)"
                    showError = true
                    isSigningOut = false
                }
            }
        }
    }
} 
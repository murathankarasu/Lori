import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    @State private var showLogoutAlert = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Çıkış Yap")
                                .foregroundColor(.red)
                        }
                    }
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
                    logout()
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
    
    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            errorMessage = "Çıkış yapılırken bir hata oluştu: \(error.localizedDescription)"
            showError = true
        }
    }
} 
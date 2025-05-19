import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingLogoutAlert = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Hesap Ayarları
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Account Settings")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            NavigationLink(destination: NotificationsView()) {
                                SettingsRow(title: "Notifications", icon: "bell.fill", color: .white)
                            }
                            
                            NavigationLink(destination: HelpView()) {
                                SettingsRow(title: "Help", icon: "questionmark.circle.fill", color: .white)
                            }
                            
                            NavigationLink(destination: AboutView()) {
                                SettingsRow(title: "About", icon: "info.circle.fill", color: .white)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Uygulama Ayarları
                    VStack(alignment: .leading, spacing: 15) {
                        Text("App Settings")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            NavigationLink(destination: SupportTicketView()) {
                                SettingsRow(title: "Support Request", icon: "envelope.fill", color: .white)
                            }
                            
                            Button(action: {
                                showingLogoutAlert = true
                            }) {
                                SettingsRow(title: "Log Out", icon: "rectangle.portrait.and.arrow.right", color: .red)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                viewModel.signOut()
                isLoggedIn = false
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .semibold))
        }
    }
}

class SettingsViewModel: ObservableObject {
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}


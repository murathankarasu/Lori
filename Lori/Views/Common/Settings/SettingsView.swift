import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingLogoutAnimation = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Header with Back Button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Text("Settings")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible placeholder for balance
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 80, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Account Settings Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Account Settings")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 25)
                            
                            VStack(spacing: 0) {
                                NavigationLink(destination: NotificationsView()) {
                                    ModernSettingsRow(
                                        title: "Notifications", 
                                        subtitle: "Manage your notification preferences",
                                        icon: "bell.fill", 
                                        iconColor: .blue,
                                        isFirst: true
                                    )
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                NavigationLink(destination: HelpView()) {
                                    ModernSettingsRow(
                                        title: "Help", 
                                        subtitle: "Frequently asked questions and support",
                                        icon: "questionmark.circle.fill", 
                                        iconColor: .green
                                    )
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                NavigationLink(destination: AboutView()) {
                                    ModernSettingsRow(
                                        title: "About", 
                                        subtitle: "App information and version",
                                        icon: "info.circle.fill", 
                                        iconColor: .orange,
                                        isLast: true
                                    )
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // App Settings Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "gear.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("App Settings")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 25)
                            
                            VStack(spacing: 0) {
                                NavigationLink(destination: SupportTicketView()) {
                                    ModernSettingsRow(
                                        title: "Support Ticket", 
                                        subtitle: "Report an issue or send feedback",
                                        icon: "envelope.fill", 
                                        iconColor: .purple,
                                        isFirst: true
                                    )
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                Button(action: {
                                    showingLogoutAnimation = true
                                }) {
                                    ModernSettingsRow(
                                        title: "Sign Out", 
                                        subtitle: "Sign out of your account securely",
                                        icon: "rectangle.portrait.and.arrow.right", 
                                        iconColor: .red,
                                        isLast: true,
                                        isDestructive: true
                                    )
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // App Version Footer
                        VStack(spacing: 8) {
                            Text("Lorien")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Version 1.0.0")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingLogoutAnimation) {
            LogoutAnimationView(isLoggedIn: $isLoggedIn)
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


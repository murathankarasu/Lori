import SwiftUI

struct AboutView: View {
    @State private var isAnimating = false
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
                            
                            Text("Geri")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Text("Hakkında")
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
                        // App Info Section
                        VStack(spacing: 20) {
                            // App Logo and Info
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                        .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                                    
                                    Text("L")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .scaleEffect(isAnimating ? 1.0 : 0.8)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isAnimating)
                                
                                VStack(spacing: 8) {
                                    Text("Lorien")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("Sürüm 1.0.0")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("Sosyal medya deneyiminizi yeniden tanımlıyoruz")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .padding(.vertical, 30)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // App Details
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Uygulama Detayları")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 25)
                            
                            VStack(spacing: 0) {
                                ModernDetailRow(
                                    title: "Geliştirici",
                                    value: "Lorien Team",
                                    icon: "person.2.fill",
                                    iconColor: .blue,
                                    isFirst: true
                                )
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                ModernDetailRow(
                                    title: "Telif Hakkı",
                                    value: "© 2024 Lorien",
                                    icon: "c.circle.fill",
                                    iconColor: .green
                                )
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                ModernDetailRow(
                                    title: "Lisans",
                                    value: "Tüm hakları saklıdır",
                                    icon: "checkmark.shield.fill",
                                    iconColor: .orange,
                                    isLast: true
                                )
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
                        
                        // Links Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Önemli Bağlantılar")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 25)
                            
                            VStack(spacing: 0) {
                                Button(action: {}) {
                                    ModernSettingsRow(
                                        title: "Gizlilik Politikası",
                                        subtitle: "Verilerinizi nasıl koruduğumuzu öğrenin",
                                        icon: "lock.fill",
                                        iconColor: .purple,
                                        isFirst: true
                                    )
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                Button(action: {}) {
                                    ModernSettingsRow(
                                        title: "Kullanım Koşulları",
                                        subtitle: "Hizmet şartlarımızı inceleyin",
                                        icon: "doc.text.fill",
                                        iconColor: .cyan
                                    )
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                Button(action: {}) {
                                    ModernSettingsRow(
                                        title: "Açık Kaynak Lisansları",
                                        subtitle: "Kullandığımız kütüphaneler",
                                        icon: "chevron.left.forwardslash.chevron.right",
                                        iconColor: .mint,
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
                        
                        // Contact Section
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "phone.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("İletişim")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 25)
                            
                            VStack(spacing: 16) {
                                ModernContactRow(
                                    title: "E-posta",
                                    value: "info@lorien.app",
                                    icon: "envelope.fill",
                                    iconColor: .red
                                )
                                
                                ModernContactRow(
                                    title: "Destek",
                                    value: "support@lorien.app",
                                    icon: "headphones.circle.fill",
                                    iconColor: .indigo
                                )
                                
                                ModernContactRow(
                                    title: "Sosyal Medya",
                                    value: "@lorienapp",
                                    icon: "at.circle.fill",
                                    iconColor: .pink
                                )
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 20)
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
                        
                        // Footer
                        VStack(spacing: 8) {
                            Text("❤️ ile geliştirildi")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Türkiye'de")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

// Modern Components
struct ModernDetailRow: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    var isFirst: Bool = false
    var isLast: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

struct ModernContactRow: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {
                // Handle contact action
            }) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
        }
    }
}

// Yardımcı Bileşenler
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.gray)
        }
    }
}

struct LinkRow: View {
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

struct SocialMediaButton: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Sosyal medya bağlantısı
        }) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

struct ContactRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
} 

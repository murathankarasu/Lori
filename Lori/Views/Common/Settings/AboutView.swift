import SwiftUI

struct AboutView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Logo ve Uygulama Bilgileri
                    VStack(spacing: 15) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(20)
                            .shadow(radius: 10)
                        
                        Text("Lori")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Versiyon 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Uygulama Detayları
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Uygulama Detayları")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            DetailRow(title: "Geliştirici", value: "Lori Team")
                            DetailRow(title: "Telif Hakkı", value: "© 2024 Lori")
                            DetailRow(title: "Lisans", value: "Tüm hakları saklıdır")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Bağlantılar
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Bağlantılar")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            LinkRow(title: "Gizlilik Politikası", icon: "lock.fill", color: .white)
                            LinkRow(title: "Kullanım Koşulları", icon: "doc.text.fill", color: .white)
                            LinkRow(title: "Lisans", icon: "checkmark.shield.fill", color: .white)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Sosyal Medya
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Sosyal Medya")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            SocialMediaButton(icon: "link", color: .white)
                            SocialMediaButton(icon: "envelope.fill", color: .white)
                            SocialMediaButton(icon: "phone.fill", color: .white)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // İletişim
                    VStack(alignment: .leading, spacing: 15) {
                        Text("İletişim")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            ContactRow(title: "E-posta", value: "info@lori.com", icon: "envelope.fill", color: .white)
                            ContactRow(title: "Telefon", value: "+90 555 555 55 55", icon: "phone.fill", color: .white)
                            ContactRow(title: "Adres", value: "İstanbul, Türkiye", icon: "location.fill", color: .white)
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
        .navigationTitle("Hakkında")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
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

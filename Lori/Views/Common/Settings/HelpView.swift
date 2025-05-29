import SwiftUI

struct HelpView: View {
    @State private var searchText = ""
    @State private var isAnimating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
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
                    
                    Text("Yardım")
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
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 16))
                            
                            TextField("Yardımda ara...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        
                        // Ana Kategoriler
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "folder.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Ana Kategoriler")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 25)
                            
                            VStack(spacing: 0) {
                                Button(action: {
                                    alertMessage = "Sık sorulan sorularımızı buradan inceleyebilirsiniz."
                                    showAlert = true
                                }) {
                                    ModernSettingsRow(
                                        title: "Sık Sorulan Sorular",
                                        subtitle: "En çok merak edilen konular",
                                        icon: "questionmark.circle.fill",
                                        iconColor: .blue,
                                        isFirst: true
                                    )
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 20)
                                
                                Button(action: {
                                    alertMessage = "Uygulamayı kullanma kılavuzunu buradan bulabilirsiniz."
                                    showAlert = true
                                }) {
                                    ModernSettingsRow(
                                        title: "Kullanıcı Kılavuzu",
                                        subtitle: "Adım adım kullanım talimatları",
                                        icon: "book.fill",
                                        iconColor: .green,
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
                        
                        // Hızlı Yardım
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "bolt.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                
                                Text("Hızlı Yardım")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 25)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    QuickHelpCard(
                                        title: "Profil Ayarları",
                                        icon: "person.fill",
                                        color: .cyan
                                    )
                                    .onTapGesture {
                                        alertMessage = "Profil ayarlarınızı değiştirmek için:\n1. Profil fotoğrafınızı değiştirmek için fotoğrafa tıklayın\n2. Kullanıcı adınızı değiştirmek için düzenle butonuna tıklayın\n3. Değişiklikleri kaydetmek için kaydet butonuna tıklayın"
                                        showAlert = true
                                    }
                                    
                                    QuickHelpCard(
                                        title: "Bildirimler",
                                        icon: "bell.fill",
                                        color: .orange
                                    )
                                    .onTapGesture {
                                        alertMessage = "Bildirim ayarlarınızı yönetmek için:\n1. Bildirimler sekmesine gidin\n2. İstediğiniz bildirim türünü seçin\n3. Bildirim sıklığını ayarlayın"
                                        showAlert = true
                                    }
                                    
                                    QuickHelpCard(
                                        title: "Güvenlik",
                                        icon: "lock.fill",
                                        color: .red
                                    )
                                    .onTapGesture {
                                        alertMessage = "Güvenlik ayarlarınızı yönetmek için:\n1. Güvenlik sekmesine gidin\n2. Şifrenizi değiştirin\n3. İki faktörlü doğrulamayı etkinleştirin"
                                        showAlert = true
                                    }
                                    
                                    QuickHelpCard(
                                        title: "Gizlilik",
                                        icon: "eye.slash.fill",
                                        color: .purple
                                    )
                                    .onTapGesture {
                                        alertMessage = "Gizlilik ayarlarınızı yönetmek için:\n1. Gizlilik sekmesine gidin\n2. Profil görünürlüğünü ayarlayın\n3. Veri paylaşım tercihlerinizi belirleyin"
                                        showAlert = true
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Yardım", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

// Yardımcı Bileşenler
struct HelpCategoryRow: View {
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

struct QuickHelpCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 110, height: 100)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// Alt View'lar
struct FAQView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            List {
                ForEach(faqItems) { item in
                    FAQItemRow(item: item)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("FAQ")
    }
}

struct FAQItemRow: View {
    let item: FAQItem
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(item.question)
                        .foregroundColor(.white)
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            
            if isExpanded {
                Text(item.answer)
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 8)
    }
}

struct UserGuideView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(guideItems) { item in
                        GuideItemCard(item: item)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("User Guide")
    }
}

struct GuideItemCard: View {
    let item: GuideItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: item.icon)
                    .foregroundColor(item.color)
                    .font(.title2)
                
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(item.description)
                .foregroundColor(.gray)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// Model
struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct GuideItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// Örnek Veriler
let faqItems = [
    FAQItem(question: "Hesabımı nasıl oluşturabilirim?", answer: "Uygulama açılış ekranında 'Kayıt Ol' butonuna tıklayarak yeni bir hesap oluşturabilirsiniz."),
    FAQItem(question: "Şifremi nasıl sıfırlayabilirim?", answer: "Giriş ekranında 'Şifremi Unuttum' seçeneğine tıklayarak şifre sıfırlama işlemini başlatabilirsiniz."),
    FAQItem(question: "Profilimi nasıl düzenleyebilirim?", answer: "Ayarlar menüsünden 'Profil Düzenle' seçeneğine giderek profil bilgilerinizi güncelleyebilirsiniz.")
]

let guideItems = [
    GuideItem(title: "Başlangıç", description: "Uygulamayı ilk kez kullanıyorsanız, bu rehber size yardımcı olacaktır.", icon: "star.fill", color: .yellow),
    GuideItem(title: "Profil Yönetimi", description: "Profilinizi nasıl düzenleyeceğinizi ve özelleştireceğinizi öğrenin.", icon: "person.fill", color: .blue),
    GuideItem(title: "İçerik Paylaşımı", description: "Fotoğraf ve video paylaşımı hakkında bilmeniz gerekenler.", icon: "photo.fill", color: .green)
] 
import SwiftUI

struct HelpView: View {
    @State private var searchText = ""
    @State private var isAnimating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Arama Çubuğu
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                        
                        TextField("Yardım ara...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Ana Kategoriler
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Ana Kategoriler")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            HelpCategoryRow(title: "Sık Sorulan Sorular", icon: "questionmark.circle.fill", color: .white)
                            HelpCategoryRow(title: "Kullanıcı Kılavuzu", icon: "book.fill", color: .white)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Hızlı Yardım
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Hızlı Yardım")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                QuickHelpCard(title: "Profil Ayarları", icon: "person.fill", color: .white)
                                    .onTapGesture {
                                        alertMessage = "Profil ayarlarınızı değiştirmek için:\n1. Profil fotoğrafınızı değiştirmek için fotoğrafa tıklayın\n2. Kullanıcı adınızı değiştirmek için düzenle butonuna tıklayın\n3. Değişiklikleri kaydetmek için kaydet butonuna tıklayın"
                                        showAlert = true
                                    }
                                
                                QuickHelpCard(title: "Bildirimler", icon: "bell.fill", color: .white)
                                    .onTapGesture {
                                        alertMessage = "Bildirim ayarlarınızı yönetmek için:\n1. Bildirimler sekmesine gidin\n2. İstediğiniz bildirim türünü seçin\n3. Bildirim sıklığını ayarlayın"
                                        showAlert = true
                                    }
                                
                                QuickHelpCard(title: "Güvenlik", icon: "lock.fill", color: .white)
                                    .onTapGesture {
                                        alertMessage = "Güvenlik ayarlarınızı yönetmek için:\n1. Güvenlik sekmesine gidin\n2. Şifrenizi değiştirin\n3. İki faktörlü doğrulamayı etkinleştirin"
                                        showAlert = true
                                    }
                                
                                QuickHelpCard(title: "Gizlilik", icon: "eye.slash.fill", color: .white)
                                    .onTapGesture {
                                        alertMessage = "Gizlilik ayarlarınızı yönetmek için:\n1. Gizlilik sekmesine gidin\n2. Profil görünürlüğünü ayarlayın\n3. Veri paylaşım tercihlerinizi belirleyin"
                                        showAlert = true
                                    }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Yardım")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
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
        .navigationTitle("SSS")
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
        .navigationTitle("Kullanım Kılavuzu")
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
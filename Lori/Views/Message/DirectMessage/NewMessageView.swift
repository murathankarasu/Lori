import SwiftUI
import Firebase
import Kingfisher

// Yeni mesaj oluşturma ekranı
struct NewMessageView: View {
    @ObservedObject var viewModel: DirectMessageViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedUserId: String? = nil
    @State private var isShowingChatView = false
    @State private var createdConversationId: String? = nil
    @State private var navigateToChatScreen = false
    
    // Başlangıçta seçilen kullanıcı
    var initialSelectedUserId: String? = nil
    
    init(viewModel: DirectMessageViewModel, initialSelectedUserId: String? = nil) {
        self.viewModel = viewModel
        self.initialSelectedUserId = initialSelectedUserId
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Başlık
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("İptal")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("Yeni Mesaj")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            if let receiverId = selectedUserId {
                                Task {
                                    // Başlangıç mesajı olarak "Merhaba" gönder
                                    let initialMessage = "Merhaba"
                                    createdConversationId = await viewModel.startNewConversation(with: receiverId, initialMessage: initialMessage)
                                    
                                    if let conversationId = createdConversationId {
                                        // Konuşma oluşturulduktan sonra mesajları yükle
                                        await viewModel.loadMessages(for: conversationId)
                                        
                                        // Ana thread üzerinde UI güncellemesi yap
                                        DispatchQueue.main.async {
                                            navigateToChatScreen = true
                                            // Kısa bir gecikme sonra modal ekranı kapat
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                        }) {
                            Text("İleri")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selectedUserId != nil ? .white : .gray)
                        }
                        .disabled(selectedUserId == nil)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    // Arama alanı
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                        
                        ZStack(alignment: .leading) {
                            if viewModel.userSearchText.isEmpty {
                                Text("Kullanıcı ara")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 16))
                            }
                            
                            TextField("", text: $viewModel.userSearchText)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        if !viewModel.userSearchText.isEmpty {
                            Button(action: {
                                viewModel.userSearchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    // Kime: etiketi
                    HStack {
                        Text("Kime:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    
                    // İçerik bölümü
                    ZStack {
                        if viewModel.isLoading {
                            // Yükleme göstergesi
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.white)
                                
                                Text("Aranıyor...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if viewModel.userSearchText.isEmpty && viewModel.suggestedUsers.isEmpty && viewModel.followingUsers.isEmpty && initialSelectedUserId == nil {
                            // Boş durum görünümü
                            emptyStateView
                        } else if !viewModel.userSearchText.isEmpty && viewModel.searchedUsers.isEmpty {
                            // Sonuç bulunamadı
                            noResultsView
                        } else {
                            // Kullanıcı listesi
                            userListView
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Component görünür olduğunda takip edilen ve önerilen kullanıcıları yükle
                Task {
                    await viewModel.loadSuggestedUsers()
                    await viewModel.loadFollowingUsers()
                }
            }
            .background(
                NavigationLink(
                    destination: createdConversationId != nil ? ChatView(conversationId: createdConversationId!, viewModel: viewModel) : nil,
                    isActive: $navigateToChatScreen
                ) {
                    EmptyView()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Boş durum görünümü
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("Mesaj Gönder")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            Text("En çok etkileşime girdiğin kişiler veya kullanıcı adını arayarak mesaj gönderebilirsin.")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Sonuç bulunamadı görünümü
    private var noResultsView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                
                VStack(spacing: 8) {
                    Text("Kullanıcı bulunamadı")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Farklı bir kullanıcı adı, e-posta veya kullanıcı ID'si ile aramayı deneyin")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            // Önerilen arama terimleri
            VStack(spacing: 12) {
                Text("Arama önerileri:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                VStack(spacing: 8) {
                    Text("• Tam kullanıcı adıyla aramayı deneyin")
                    Text("• Daha iyi sonuçlar için e-posta adresi kullanın")
                    Text("• Kullanıcı ID'si ile arama yapın")
                }
                .font(.system(size: 14))
                .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Kullanıcı listesi görünümü
    private var userListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Arama yapılıyorsa arama sonuçlarını göster
                if !viewModel.userSearchText.isEmpty {
                    ForEach(viewModel.searchedUsers) { user in
                        if user.id != viewModel.userId {
                            userRow(user: user)
                            
                            if user.id != viewModel.searchedUsers.last?.id {
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                } else {
                    // Önerilen kullanıcılar bölümü
                    if !viewModel.suggestedUsers.isEmpty {
                        sectionHeader(title: "En Çok Etkileşime Girdiğin Kişiler", subtitle: "Sık iletişim kurduğun kişiler")
                        
                        ForEach(viewModel.suggestedUsers) { user in
                            if user.id != viewModel.userId {
                                userRow(user: user, showInteractionBadge: true)
                                
                                if user.id != viewModel.suggestedUsers.last?.id {
                                    Divider()
                                        .background(Color.gray.opacity(0.2))
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    
                    // Takip edilen kullanıcılar bölümü
                    if !viewModel.followingUsers.isEmpty {
                        if !viewModel.suggestedUsers.isEmpty {
                            Divider()
                                .background(Color.gray.opacity(0.4))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                        }
                        
                        sectionHeader(title: "Takip Ettiğin Kişiler", subtitle: "Takip ettiğin kişiler listesi")
                        
                        ForEach(viewModel.followingUsers) { user in
                            if user.id != viewModel.userId {
                                userRow(user: user)
                                
                                if user.id != viewModel.followingUsers.last?.id {
                                    Divider()
                                        .background(Color.gray.opacity(0.2))
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Helper Views
    
    // Bölüm başlığı
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // Kullanıcı satırı
    private func userRow(user: User, showInteractionBadge: Bool = false) -> some View {
        Button(action: {
            selectedUserId = user.id
        }) {
            HStack(spacing: 12) {
                // Profil resmi
                if let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                    KFImage(URL(string: profileImageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }
                
                // Kullanıcı bilgileri
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(user.username)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 12))
                        }
                        
                        if showInteractionBadge {
                            Text("Sık etkileşim")
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(user.email)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Seçim göstergesi
                if selectedUserId == user.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                selectedUserId == user.id ? Color.white.opacity(0.1) : Color.clear
            )
        }
    }
} 
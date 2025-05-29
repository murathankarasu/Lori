import SwiftUI
import Firebase
import Kingfisher

// Sohbet ekranı
struct ChatView: View {
    let conversationId: String
    @ObservedObject var viewModel: DirectMessageViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var isShowingError = false
    @State private var showingProfile = false
    @State private var showingDeleteConfirmation = false
    @State private var isNotificationsMuted = false
    @State private var selectedImage: UIImage?
    var hideHeader: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Başlık - hideHeader true ise gizle
                if !hideHeader {
                    HStack(spacing: 16) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        // Profil fotoğrafı ve kullanıcı adı - Tıklanabilir profil görüntüleme için
                        Button(action: {
                            if let otherUserId = otherUserId {
                                showingProfile = true
                            }
                        }) {
                            HStack(spacing: 12) {
                                // Profil fotoğrafı - Kingfisher ile
                                if let user = otherUser, let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                                    KFImage(URL(string: profileImageUrl))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Text(otherUserInitial)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(otherUserName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Menü butonu
                        Menu {
                            Button(action: {
                                isNotificationsMuted.toggle()
                            }) {
                                if isNotificationsMuted {
                                    Label("Bildirimleri Aç", systemImage: "bell")
                                } else {
                                    Label("Sessize Al", systemImage: "bell.slash")
                                }
                            }
                            
                            Button(action: {
                                if let otherUserId = otherUserId {
                                    showingProfile = true
                                }
                            }) {
                                Label("Profili Görüntüle", systemImage: "person.circle")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                showingDeleteConfirmation = true
                            }) {
                                Label("Sohbeti Sil", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    
                    Divider()
                        .background(Color.gray.opacity(0.2))
                }
                
                // Mesaj listesi
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    Spacer()
                } else if viewModel.currentConversationMessages.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "message.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text("Henüz mesaj yok")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Merhaba de ve sohbeti başlat!")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                } else {
                    ScrollViewReader { scrollView in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.currentConversationMessages) { message in
                                    MessageBubble(message: message, isFromCurrentUser: message.senderId == viewModel.userId)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                        .onChange(of: viewModel.currentConversationMessages.count) { _ in
                            if let lastMessage = viewModel.currentConversationMessages.last {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onAppear {
                            if let lastMessage = viewModel.currentConversationMessages.last {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Mesaj gönderme alanı
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    HStack(spacing: 12) {
                        // Fotoğraf ekleme butonu
                        Button(action: {
                            showingActionSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        
                        // Mesaj yazma alanı - Renkler değiştirildi (siyah arka plan, beyaz yazı)
                        HStack(spacing: 8) {
                            TextField("Mesaj...", text: $viewModel.newMessageText, axis: .vertical)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.black)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.white) // Beyaz metin rengi
                                .font(.system(size: 16))
                                .lineLimit(1...5)
                            
                            // Gönder butonu - Heart icon kaldırıldı
                            Button(action: {
                                sendMessage()
                            }) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            .disabled(viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            // Konuşma mesajlarını yükle ve durumu logla
            print("[ChatView] Mesajlar yükleniyor - conversationId: \(conversationId)")
            await viewModel.loadMessages(for: conversationId)
            print("[ChatView] Mesaj yükleme tamamlandı - toplam mesaj: \(viewModel.currentConversationMessages.count)")
            
            // Diğer kullanıcının bilgilerini önbelleğe al
            if let conversation = viewModel.conversations.first(where: { $0.id == conversationId }),
               let otherUserId = conversation.users.first(where: { $0 != viewModel.userId }) {
                await viewModel.loadUserInfo(for: otherUserId)
                
                // Diğer kullanıcının profil resmini önceden yükle
                if let user = viewModel.userCache[otherUserId], 
                   let profileImageUrl = user.profileImageUrl, 
                   !profileImageUrl.isEmpty,
                   let url = URL(string: profileImageUrl) {
                    Task { @MainActor in
                        let prefetcher = ImagePrefetcher(urls: [url])
                        prefetcher.start()
                    }
                }
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Medya Ekle"),
                buttons: [
                    .default(Text("Fotoğraf Çek")) {
                        // Kamera açma
                    },
                    .default(Text("Fotoğraf Seç")) {
                        showingImagePicker = true
                    },
                    .cancel(Text("İptal"))
                ]
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                sendImageMessage(image: image)
                selectedImage = nil // Reset after sending
            }
        }
        .alert(isPresented: $isShowingError) {
            Alert(
                title: Text("Hata"),
                message: Text(viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu"),
                dismissButton: .default(Text("Tamam"))
            )
        }
        .onChange(of: viewModel.errorMessage) { error in
            isShowingError = error != nil
        }
        // Profil Görüntüleme - sheet yerine fullScreenCover kullanılıyor
        .fullScreenCover(isPresented: $showingProfile) {
            if let userId = otherUserId {
                ProfileView(userId: userId, fromChatView: true)
            }
        }
        // Sohbeti silme onayı
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Sohbeti Sil"),
                message: Text("Bu sohbeti silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
                primaryButton: .destructive(Text("Sil")) {
                    deleteConversation()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func sendMessage() {
        // Bu konuşmadaki diğer kullanıcının ID'sini al
        if let conversation = viewModel.conversations.first(where: { $0.id == conversationId }),
           let otherUserId = conversation.users.first(where: { $0 != viewModel.userId }) {
            Task {
                await viewModel.sendMessage(to: conversationId, receiverId: otherUserId)
            }
        }
    }
    
    private func sendImageMessage(image: UIImage) {
        // Bu konuşmadaki diğer kullanıcının ID'sini al
        if let conversation = viewModel.conversations.first(where: { $0.id == conversationId }),
           let otherUserId = conversation.users.first(where: { $0 != viewModel.userId }) {
            Task {
                await viewModel.sendImageMessage(image: image, to: conversationId, receiverId: otherUserId)
            }
        }
    }
    
    // Diğer kullanıcının bilgileri
    private var otherUser: User? {
        guard let conversation = viewModel.conversations.first(where: { $0.id == conversationId }),
              let otherUserId = conversation.users.first(where: { $0 != viewModel.userId }) else {
            return nil
        }
        return viewModel.userCache[otherUserId]
    }
    
    private var otherUserId: String? {
        guard let conversation = viewModel.conversations.first(where: { $0.id == conversationId }) else {
            return nil
        }
        return conversation.users.first(where: { $0 != viewModel.userId })
    }
    
    private var otherUserName: String {
        return otherUser?.username ?? "Kullanıcı"
    }
    
    private var otherUserInitial: String {
        return String(otherUserName.prefix(1).uppercased())
    }
    
    private func deleteConversation() {
        Task {
            await viewModel.deleteConversation(conversationId)
            presentationMode.wrappedValue.dismiss()
        }
    }
} 

import SwiftUI
import FirebaseAuth
import Kingfisher

// MARK: - DirectMessage Views

// Başlangıçta belirli bir kullanıcıyla sohbet başlatacak görünüm
struct DirectMessageWithUserView: View {
    let currentUserId: String
    let targetUserId: String
    @StateObject private var viewModel: DirectMessageViewModel
    @State private var conversationId: String? = nil
    @State private var isCreatingConversation = false
    @State private var shouldShowChat = false
    @Environment(\.dismiss) private var dismiss
    
    init(currentUserId: String, targetUserId: String) {
        self.currentUserId = currentUserId
        self.targetUserId = targetUserId
        self._viewModel = StateObject(wrappedValue: DirectMessageViewModel(userId: currentUserId))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if isCreatingConversation || !shouldShowChat {
                    ChatBubbleLoadingAnimation()
                        .onAppear {
                            // Animasyonun tamamlanmasını bekle, sonra sohbeti göster
                            if conversationId != nil && !shouldShowChat {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                                    shouldShowChat = true
                                }
                            }
                        }
                } else if conversationId != nil {
                    // Konuşma hazır olduğunda doğrudan ChatView'ı göster
                    ChatViewWithBackButton(conversationId: conversationId!, viewModel: viewModel, onBackTapped: {
                        // Profil ekranını kapatıp Featured ekranına dönüş
                        dismiss()
                    })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            startOrOpenConversation()
        }
    }
    
    private func startOrOpenConversation() {
        isCreatingConversation = true
        
        // İlk olarak mevcut konuşmaları yükle
        Task {
            await viewModel.loadConversations()
            
            // Kullanıcıyla mevcut bir konuşma var mı kontrol et
            if let existingConversation = viewModel.conversations.first(where: { conversation in
                conversation.users.contains(targetUserId) && conversation.users.contains(currentUserId)
            }) {
                // Mevcut konuşmayı aç
                if let conversationId = existingConversation.id {
                    await viewModel.loadMessages(for: conversationId)
                    
                    DispatchQueue.main.async {
                        self.conversationId = conversationId
                        self.isCreatingConversation = false
                        
                        // Animasyonun tamamlanmasını bekle, en az 4.5 saniye göster
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                            self.shouldShowChat = true
                        }
                    }
                }
            } else {
                // Yeni konuşma başlat
                let initialMessage = "Hello"
                let newConversationId = await viewModel.startNewConversation(with: targetUserId, initialMessage: initialMessage)
                
                if let conversationId = newConversationId {
                    await viewModel.loadMessages(for: conversationId)
                    
                    DispatchQueue.main.async {
                        self.conversationId = conversationId
                        self.isCreatingConversation = false
                        
                        // Animasyonun tamamlanmasını bekle, en az 4.5 saniye göster
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                            self.shouldShowChat = true
                        }
                    }
                } else {
                    // Hata durumu
                    DispatchQueue.main.async {
                        isCreatingConversation = false
                    }
                }
            }
        }
    }
}

// ChatView'ı saran ve geri butonuna özel davranış ekleyen bir view
struct ChatViewWithBackButton: View {
    let conversationId: String
    @ObservedObject var viewModel: DirectMessageViewModel
    let onBackTapped: () -> Void
    @State private var showingProfile = false
    @State private var isNotificationsMuted = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Özel başlık - geri butonu tıklandığında sohbet listesine gider
                HStack(spacing: 16) {
                    Button(action: {
                        onBackTapped()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Profil fotoğrafı ve kullanıcı adı - Tıklanabilir
                    Button(action: {
                        if otherUserId != nil {
                            showingProfile = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            // Profil fotoğrafı ve kullanıcı adı - Aynı ChatView'daki gibi
                            if let otherUser = otherUser, let profileImageUrl = otherUser.profileImageUrl, !profileImageUrl.isEmpty {
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
                                        Text(otherUserName)
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
                                Label("Enable Notifications", systemImage: "bell")
                            } else {
                                Label("Mute", systemImage: "bell.slash")
                            }
                        }
                        
                        Button(action: {
                            if otherUserId != nil {
                                showingProfile = true
                            }
                        }) {
                            Label("View Profile", systemImage: "person.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            // Konuşmayı silme onayını göster
                            showingDeleteConfirmation = true
                        }) {
                            Label("Delete Chat", systemImage: "trash")
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
                
                // ChatView içeriği
                ChatView(conversationId: conversationId, viewModel: viewModel, hideHeader: true)
            }
        }
        // Profil Görüntüleme
        .fullScreenCover(isPresented: $showingProfile) {
            if let userId = otherUserId {
                ProfileView(userId: userId, fromChatView: true)
            }
        }
        // Sohbeti silme onayı
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Chat"),
                message: Text("Are you sure you want to delete this chat? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteConversation()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // Konuşmayı sil
    private func deleteConversation() {
        Task {
            await viewModel.deleteConversation(conversationId)
            // Silme işleminden sonra geri dön
            onBackTapped()
        }
    }
    
    // Diğer kullanıcının bilgileri - ChatView'dan kopyalandı
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
        return otherUser?.username ?? "User"
    }
} 
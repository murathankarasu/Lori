import Foundation
import SwiftUI
import Firebase
import Combine

class DirectMessageViewModel: ObservableObject {
    @Published var conversations: [DirectMessageConversation] = []
    @Published var currentConversationMessages: [DirectMessage] = []
    @Published var selectedConversation: DirectMessageConversation?
    @Published var newMessageText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var followingUsers: [User] = [] // Takip edilen kullanıcılar
    @Published var searchedUsers: [User] = [] // Aranan kullanıcılar
    @Published var userSearchText: String = "" // Kullanıcı arama metni
    
    private var cancellables = Set<AnyCancellable>()
    private let messageService = DirectMessageService()
    var userId: String // Bu değişkeni public yapıyorum ki başka yerlerden erişilebilsin
    
    init(userId: String) {
        self.userId = userId
        
        // Konuşma arama metni değişikliklerini dinle
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.filterConversations()
            }
            .store(in: &cancellables)
        
        // Kullanıcı arama metni değişikliklerini dinle
        $userSearchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                guard let self = self, !searchText.isEmpty else {
                    self?.searchedUsers = []
                    return
                }
                Task {
                    await self.searchUsers(query: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    // Filtrelenmiş sohbetleri döndürür
    var filteredConversations: [DirectMessageConversation] {
        if searchText.isEmpty {
            return conversations
        }
        return conversations.filter { conversation in
            // TODO: Daha kapsamlı filtreleme: Diğer kullanıcının adını veya kullanıcı adını da kontrol et
            conversation.lastMessage.lowercased().contains(searchText.lowercased())
        }
    }
    
    private func filterConversations() {
        objectWillChange.send()
    }
    
    // Kullanıcıları ara
    func searchUsers(query: String) async {
        // isLoading = true // Arama sırasında yükleme göstergesi için isteğe bağlı
        do {
            let users = try await messageService.searchUsers(with: query)
            DispatchQueue.main.async {
                self.searchedUsers = users
                // self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Kullanıcılar aranırken hata oluştu: \(error.localizedDescription)"
                // self.isLoading = false
            }
        }
    }
    
    // Takip edilen kullanıcıları yükle
    func loadFollowingUsers() async {
        isLoading = true
        
        do {
            let users = try await messageService.fetchUserFollowing(for: userId)
            DispatchQueue.main.async {
                self.followingUsers = users
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Takip edilen kullanıcılar yüklenemedi: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Kullanıcının konuşmalarını yükle
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedConversations = try await messageService.fetchUserConversations(for: userId)
            DispatchQueue.main.async {
                self.conversations = fetchedConversations
                self.isLoading = false
            }
            
            // Konuşma yoksa takip edilen kullanıcıları getir
            if fetchedConversations.isEmpty {
                await loadFollowingUsers()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Konuşmalar yüklenemedi: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Belirli bir konuşmanın mesajlarını yükle
    func loadMessages(for conversationId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedMessages = try await messageService.fetchMessages(for: conversationId)
            try await messageService.markMessagesAsRead(in: conversationId, for: userId)
            
            DispatchQueue.main.async {
                self.currentConversationMessages = fetchedMessages
                self.isLoading = false
                
                // Konuşmadaki son mesajın okundu durumunu güncelle
                if let index = self.conversations.firstIndex(where: { $0.id == conversationId }) {
                    self.conversations[index].lastMessageRead = true
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Mesajlar yüklenemedi: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Mesaj gönder
    func sendMessage(to conversationId: String, receiverId: String) async {
        guard !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let messageContent = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // UI'ı hemen güncellemek için geçici mesaj oluştur
        let tempMessage = DirectMessage(
            id: UUID().uuidString,
            senderId: userId,
            receiverId: receiverId,
            content: messageContent,
            timestamp: Date(),
            isRead: false,
            imageURL: nil
        )
        
        DispatchQueue.main.async {
            self.currentConversationMessages.append(tempMessage)
            self.newMessageText = ""
        }
        
        do {
            try await messageService.sendMessage(to: conversationId, message: tempMessage)
            await loadConversations() // Konuşma listesini güncelle
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Mesaj gönderilemedi: \(error.localizedDescription)"
                // Hata durumunda geçici mesajı kaldır
                self.currentConversationMessages.removeAll(where: { $0.id == tempMessage.id })
            }
        }
    }
    
    // Yeni konuşma başlat
    func startNewConversation(with receiverId: String, initialMessage: String? = nil) async -> String? {
        // Başlangıç mesajı boş olsa bile devam et, servis tarafında ele alınacak
        // guard let message = initialMessage, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        //     return nil
        // }
        
        do {
            let conversationId = try await messageService.createConversation(
                between: [userId, receiverId],
                initialMessage: initialMessage, // Artık nil olabilir
                senderId: userId
            )
            
            await loadConversations() // Konuşma listesini güncelle, yeni boş konuşma da gelmeli
            // await loadMessages(for: conversationId) // Yeni konuşmada mesaj olmayacağı için bu satır gereksiz olabilir
            return conversationId
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Yeni konuşma başlatılamadı: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    // Konuşmayı sil
    func deleteConversation(_ conversationId: String) async {
        do {
            try await messageService.deleteConversation(conversationId)
            
            DispatchQueue.main.async {
                self.conversations.removeAll(where: { $0.id == conversationId })
                if self.selectedConversation?.id == conversationId {
                    self.selectedConversation = nil
                    self.currentConversationMessages = []
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Konuşma silinemedi: \(error.localizedDescription)"
            }
        }
    }
} 
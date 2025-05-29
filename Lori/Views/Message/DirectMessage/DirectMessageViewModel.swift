import Foundation
import SwiftUI
import Firebase
import Combine
import UIKit
import Kingfisher

@MainActor
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
    @Published var suggestedUsers: [User] = [] // En çok etkileşime girilen önerilen kullanıcılar
    @Published var userSearchText: String = "" // Kullanıcı arama metni
    @Published var userCache: [String: User] = [:] // Kullanıcı bilgilerini cache'le
    
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
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // Daha doğru zamanlama için 300ms
            .removeDuplicates()
            .sink { [weak self] searchText in
                print("📝 userSearchText değişti: '\(searchText)'")
                guard let self = self else { return }
                
                Task {
                    // Arama metni boşsa sonuçları temizle
                    if searchText.isEmpty {
                        self.searchedUsers = []
                        self.isLoading = false
                    } else {
                        // Arama başlatıldığında yükleme durumunu güncelle
                        self.isLoading = true
                        
                        // Aramayı gerçekleştir
                        await self.searchUsers(query: searchText)
                        
                        // Arama tamamlandığında yükleme durumunu kapat
                        self.isLoading = false
                    }
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
        print("🔍 DirectMessageViewModel.searchUsers çağrıldı - Query: '\(query)'")
        do {
            print("📞 DirectMessageService.searchUsers çağrılıyor...")
            let users = try await messageService.searchUsers(with: query)
            print("✅ Arama tamamlandı - \(users.count) kullanıcı bulundu")
            self.searchedUsers = users
            print("🔄 UI güncellendi - searchedUsers: \(users.count) kullanıcı")
        } catch {
            print("❌ Arama hatası: \(error.localizedDescription)")
            self.errorMessage = "Kullanıcılar aranırken hata oluştu: \(error.localizedDescription)"
        }
    }
    
    // Takip edilen kullanıcıları yükle
    func loadFollowingUsers() async {
        isLoading = true
        
        do {
            let users = try await messageService.fetchUserFollowing(for: userId)
            self.followingUsers = users
            self.isLoading = false
        } catch {
            self.errorMessage = "Takip edilen kullanıcılar yüklenemedi: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    // En çok etkileşime girilen kullanıcıları yükle
    func loadSuggestedUsers() async {
        do {
            let users = try await messageService.fetchMostInteractedUsers(for: userId)
            self.suggestedUsers = users
        } catch {
            self.errorMessage = "Önerilen kullanıcılar yüklenemedi: \(error.localizedDescription)"
        }
    }
    
    // Kullanıcı bilgilerini yükle ve cache'le
    func loadUserInfo(for userId: String) async {
        // Cache'de varsa tekrar yükleme
        if userCache[userId] != nil {
            return
        }
        
        do {
            print("[DirectMessageViewModel] Kullanıcı bilgisi yükleniyor - userId: \(userId)")
            let user = try await messageService.fetchUser(by: userId)
            self.userCache[userId] = user
            print("[DirectMessageViewModel] Kullanıcı bilgisi başarıyla yüklendi - username: \(user.username)")
        } catch let error as NSError {
            print("[DirectMessageViewModel] Kullanıcı bilgisi yüklenemedi: \(userId) - \(error.localizedDescription)")
            // Hata durumunda cache'de boş bir değer oluşturmak yerine, hata mesajını kaydet
            if error.domain == "DirectMessageService" && error.code == 2 {
                print("[DirectMessageViewModel] Kullanıcı bulunamadı, geçici bir user objesi oluşturuluyor")
                // Geçici bir kullanıcı objesi oluştur
                let tempUser = User(
                    id: userId,
                    username: "Bilinmeyen Kullanıcı",
                    email: "",
                    profileImageUrl: nil,
                    bio: nil,
                    followers: 0,
                    following: 0,
                    createdAt: Date(),
                    isVerified: false,
                    usernameLower: "bilinmeyen kullanıcı"
                )
                self.userCache[userId] = tempUser
            }
        } catch {
            print("[DirectMessageViewModel] Kullanıcı bilgisi yüklenemedi (genel hata): \(userId) - \(error.localizedDescription)")
        }
    }
    
    // Kullanıcının konuşmalarını yükle
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedConversations = try await messageService.fetchUserConversations(for: userId)
            
            // Konuşmalardaki tüm kullanıcıların bilgilerini yükle
            var allUserIds = Set<String>()
            for conversation in fetchedConversations {
                allUserIds.formUnion(conversation.users)
            }
            allUserIds.remove(userId) // Kendi ID'sini çıkar
            
            // Kullanıcı bilgilerini paralel olarak yükle
            await withTaskGroup(of: Void.self) { group in
                for userId in allUserIds {
                    group.addTask {
                        await self.loadUserInfo(for: userId)
                    }
                }
            }
            
            self.conversations = fetchedConversations
            self.isLoading = false
            
            // Konuşma yoksa önerilen ve takip edilen kullanıcıları getir
            if fetchedConversations.isEmpty {
                await loadSuggestedUsers()
                await loadFollowingUsers()
            }
        } catch {
            self.errorMessage = "Konuşmalar yüklenemedi: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    // Belirli bir konuşmanın mesajlarını yükle
    func loadMessages(for conversationId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedMessages = try await messageService.fetchMessages(for: conversationId)
            try await messageService.markMessagesAsRead(in: conversationId, for: userId)
            
            self.currentConversationMessages = fetchedMessages
            self.isLoading = false
            
            // Konuşmadaki son mesajın okundu durumunu güncelle
            if let index = self.conversations.firstIndex(where: { $0.id == conversationId }) {
                self.conversations[index].lastMessageRead = true
            }
            
            // Arka planda profil resimlerini önceden yükle
            Task {
                await preloadProfileImages(for: fetchedMessages)
            }
        } catch {
            self.errorMessage = "Mesajlar yüklenemedi: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    // Profil resimlerini önceden yükle
    private func preloadProfileImages(for messages: [DirectMessage]) async {
        // Mesajlardaki tüm benzersiz kullanıcı ID'lerini topla
        let userIds = Set(messages.map { $0.senderId })
        
        // Her kullanıcının profil resmini önbelleğe yükle
        for userId in userIds {
            if let user = userCache[userId], let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                // Kingfisher'a resmi önceden yüklemesi için söyle
                if let url = URL(string: profileImageUrl) {
                    Task { @MainActor in
                        // Kingfisher prefetcher kullanarak resmi arka planda yükle
                        let prefetcher = ImagePrefetcher(urls: [url])
                        prefetcher.start()
                    }
                }
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
        
        self.currentConversationMessages.append(tempMessage)
        self.newMessageText = ""
        
        do {
            try await messageService.sendMessage(to: conversationId, message: tempMessage)
            await loadConversations() // Konuşma listesini güncelle
        } catch {
            self.errorMessage = "Mesaj gönderilemedi: \(error.localizedDescription)"
            // Hata durumunda geçici mesajı kaldır
            self.currentConversationMessages.removeAll(where: { $0.id == tempMessage.id })
        }
    }
    
    // Resim mesajı gönder
    func sendImageMessage(image: UIImage, to conversationId: String, receiverId: String) async {
        // UI'ı hemen güncellemek için geçici mesaj oluştur
        let tempMessage = DirectMessage(
            id: UUID().uuidString,
            senderId: userId,
            receiverId: receiverId,
            content: "📷 Fotoğraf",
            timestamp: Date(),
            isRead: false,
            imageURL: "temp_uploading" // Geçici URL
        )
        
        self.currentConversationMessages.append(tempMessage)
        
        do {
            // Resmi Firebase Storage'a yükle
            let imageURL = try await messageService.uploadImage(image, conversationId: conversationId)
            
            // Gerçek mesajı oluştur
            let imageMessage = DirectMessage(
                id: tempMessage.id,
                senderId: userId,
                receiverId: receiverId,
                content: "📷 Fotoğraf",
                timestamp: Date(),
                isRead: false,
                imageURL: imageURL
            )
            
            // Geçici mesajı gerçek mesajla değiştir
            if let index = self.currentConversationMessages.firstIndex(where: { $0.id == tempMessage.id }) {
                self.currentConversationMessages[index] = imageMessage
            }
            
            // Mesajı Firestore'a kaydet
            try await messageService.sendMessage(to: conversationId, message: imageMessage)
            await loadConversations() // Konuşma listesini güncelle
        } catch {
            self.errorMessage = "Fotoğraf gönderilemedi: \(error.localizedDescription)"
            // Hata durumunda geçici mesajı kaldır
            self.currentConversationMessages.removeAll(where: { $0.id == tempMessage.id })
        }
    }
    
    // Yeni konuşma başlat
    func startNewConversation(with receiverId: String, initialMessage: String? = nil) async -> String? {
        isLoading = true
        errorMessage = nil
        
        do {
            // Başlangıç mesajını düzenle
            var messageToSend = initialMessage
            if let message = initialMessage, message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                messageToSend = nil
            }
            
            print("[DirectMessageViewModel] Yeni konuşma başlatılıyor - receiverId: \(receiverId), initialMessage: \(messageToSend ?? "nil")")
            
            let conversationId = try await messageService.createConversation(
                between: [userId, receiverId],
                initialMessage: messageToSend,
                senderId: userId
            )
            
            print("[DirectMessageViewModel] Konuşma başarıyla oluşturuldu - ID: \(conversationId)")
            
            // Kullanıcı bilgisini önbelleğe al
            await loadUserInfo(for: receiverId)
            
            // Konuşma listesini güncelle
            await loadConversations()
            
            // Mesajları yükle
            if let initialMsg = messageToSend, !initialMsg.isEmpty {
                await loadMessages(for: conversationId)
            }
            
            self.isLoading = false
            
            return conversationId
        } catch {
            print("[DirectMessageViewModel] Konuşma oluşturma hatası: \(error.localizedDescription)")
            self.errorMessage = "Yeni konuşma başlatılamadı: \(error.localizedDescription)"
            self.isLoading = false
            return nil
        }
    }
    
    // Konuşmayı sil
    func deleteConversation(_ conversationId: String) async {
        do {
            try await messageService.deleteConversation(conversationId)
            
            self.conversations.removeAll(where: { $0.id == conversationId })
            if self.selectedConversation?.id == conversationId {
                self.selectedConversation = nil
                self.currentConversationMessages = []
            }
        } catch {
            self.errorMessage = "Konuşma silinemedi: \(error.localizedDescription)"
        }
    }
} 
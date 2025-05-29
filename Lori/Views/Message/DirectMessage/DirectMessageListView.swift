import SwiftUI
import Firebase
import Kingfisher

struct DirectMessageListView: View {
    @StateObject private var viewModel: DirectMessageViewModel
    @State private var selectedConversationId: String? = nil
    @State private var showingNewMessageView = false
    @State private var searchText = ""
    @State private var selectedFollowingUserId: String? = nil
    @Environment(\.presentationMode) var presentationMode
    
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: DirectMessageViewModel(userId: userId))
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
                            Image(systemName: "arrow.left")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("Mesajlar")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            selectedFollowingUserId = nil
                            showingNewMessageView = true
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    // Arama alanı
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                        
                        ZStack(alignment: .leading) {
                            if searchText.isEmpty {
                                Text("Mesajlarda ara")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 16))
                            }
                            
                            TextField("", text: $searchText)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: searchText) { newValue in
                                    viewModel.searchText = newValue
                                }
                        }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                viewModel.searchText = ""
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
                    .padding(.bottom, 16)
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        Spacer()
                    } else if viewModel.conversations.isEmpty {
                        // Takip edilen hesapları göster
                        if viewModel.followingUsers.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "message.circle")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray.opacity(0.6))
                                
                                Text("Henüz mesajınız yok")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("Arkadaşlarınızla mesajlaşmaya başlayın")
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    showingNewMessageView = true
                                }) {
                                    Text("Mesaj Gönder")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .cornerRadius(25)
                                }
                                .padding(.top, 8)
                            }
                            .padding(.horizontal, 40)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Text("Mesajlaşmaya başlayın")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                ScrollView {
                                    LazyVStack(spacing: 0) {
                                        ForEach(viewModel.followingUsers) { user in
                                            SuggestedUserRow(user: user) {
                                                showChat(with: user.id)
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 20)
                        }
                    } else {
                        // Konuşma listesi
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.filteredConversations) { conversation in
                                    Button(action: {
                                        // Tıklanan konuşmayı belirle
                                        selectedConversationId = conversation.id
                                        
                                        // Mesajları önceden yükle
                                        if let conversationId = conversation.id {
                                            Task {
                                                await viewModel.loadMessages(for: conversationId)
                                            }
                                        }
                                    }) {
                                        ConversationRow(conversation: conversation, userId: viewModel.userId, userCache: viewModel.userCache)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if conversation.id != viewModel.filteredConversations.last?.id {
                                        Divider()
                                            .background(Color.gray.opacity(0.2))
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .task {
                if viewModel.conversations.isEmpty {
                    await viewModel.loadConversations()
                }
            }
            .fullScreenCover(isPresented: $showingNewMessageView) {
                NewMessageView(viewModel: viewModel, initialSelectedUserId: selectedFollowingUserId)
            }
            .navigationBarHidden(true)
            .onAppear {
                setupNotificationObserver()
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(UIApplication.shared, name: NSNotification.Name("OpenDirectMessageWithUser"), object: nil)
            }
            .background(
                // ChatView için NavigationLink
                NavigationLink(
                    destination: selectedConversationId != nil ? ChatView(conversationId: selectedConversationId!, viewModel: viewModel) : nil,
                    tag: selectedConversationId ?? "",
                    selection: $selectedConversationId
                ) {
                    EmptyView()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // Bildirim dinleyicisini kur
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenDirectMessageWithUser"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let userId = userInfo["userId"] as? String {
                // Kullanıcı ID'si geldiğinde otomatik olarak yeni mesaj ekranını aç
                selectedFollowingUserId = userId
                showingNewMessageView = true
            }
        }
    }
    
    // Seçilen kullanıcı ile yeni sohbet başlat veya mevcut sohbete git
    private func showChat(with userId: String) {
        Task {
            // Kullanıcıyla mevcut bir konuşma olup olmadığını kontrol et
            if let existingConversation = viewModel.conversations.first(where: { $0.users.contains(userId) && $0.users.contains(viewModel.userId) }) {
                // Mevcut konuşma varsa, mesajları yükle
                if let conversationId = existingConversation.id {
                    await viewModel.loadMessages(for: conversationId)
                    
                    // Ana thread üzerinde UI güncellemesi yaparak ChatView'a git
                    DispatchQueue.main.async {
                        selectedConversationId = conversationId
                    }
                }
            } else {
                // Mevcut konuşma yoksa, yeni bir konuşma başlat
                if let conversationId = await viewModel.startNewConversation(with: userId, initialMessage: "Merhaba") {
                    // Yeni mesajları yükle
                    await viewModel.loadMessages(for: conversationId)
                    
                    // Ana thread üzerinde UI güncellemesi yaparak ChatView'a git
                    DispatchQueue.main.async {
                        selectedConversationId = conversationId
                    }
                }
            }
        }
    }
}

// Önerilen kullanıcı satırı
struct SuggestedUserRow: View {
    let user: User
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Profil fotoğrafı - Kingfisher ile
                if let imageUrl = user.profileImageUrl, !imageUrl.isEmpty {
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(user.username.prefix(1).uppercased())
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .semibold))
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    } else {
                        Text("Mesaj gönder")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                Button(action: action) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.blue)
                        )
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
import SwiftUI
import Firebase

struct DirectMessageListView: View {
    @StateObject private var viewModel: DirectMessageViewModel
    @State private var selectedUserId: String? = nil
    @State private var showingNewMessageView = false
    @State private var searchText = ""
    @State private var selectedFollowingUserId: String? = nil
    @Environment(\.presentationMode) var presentationMode
    
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: DirectMessageViewModel(userId: userId))
    }
    
    var body: some View {
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
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                // Arama alanı
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                    
                    TextField("Ara", text: $searchText)
                        .foregroundColor(.white)
                        .padding(8)
                        .onChange(of: searchText) { _ in
                            viewModel.searchText = searchText
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                }
                .background(Color(UIColor.darkGray).opacity(0.3))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if viewModel.conversations.isEmpty {
                    // Takip edilen hesapları göster
                    if viewModel.followingUsers.isEmpty {
                        Spacer()
                        Text("Henüz mesajınız yok")
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Mesajlaşmaya başlayabileceğiniz kişiler")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 20)
                                .padding(.horizontal)
                            
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.followingUsers) { user in
                                        SuggestedUserRow(user: user) {
                                            showChat(with: user.id)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Konuşma listesi
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.filteredConversations) { conversation in
                                ConversationRow(conversation: conversation, userId: viewModel.userId)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(
                                        NavigationLink(
                                            destination: ChatView(
                                                conversationId: conversation.id ?? "",
                                                viewModel: viewModel
                                            ),
                                            tag: conversation.id ?? "",
                                            selection: $selectedUserId
                                        ) {
                                            EmptyView()
                                        }
                                        .opacity(0)
                                    )
                                    .onTapGesture {
                                        selectedUserId = conversation.id
                                    }
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                            }
                        }
                    }
                }
            }
        }
        .task {
            if viewModel.conversations.isEmpty {
                await viewModel.loadConversations()
            }
        }
        .sheet(isPresented: $showingNewMessageView) {
            NewMessageView(viewModel: viewModel, initialSelectedUserId: selectedFollowingUserId)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Bildirim aboneliğini ekle
            setupNotificationObserver()
        }
        .onDisappear {
            // Bildirim aboneliğini kaldır
            NotificationCenter.default.removeObserver(UIApplication.shared, name: NSNotification.Name("OpenDirectMessageWithUser"), object: nil)
        }
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
            // Bu kontrol ViewModel veya Service katmanında daha merkezi bir şekilde yapılabilir.
            // Şimdilik basit bir kontrol yapıyoruz.
            if let existingConversation = viewModel.conversations.first(where: { $0.users.contains(userId) && $0.users.contains(viewModel.userId) }) {
                // Mevcut konuşma varsa, ChatView'a git
                selectedUserId = existingConversation.id // NavigationLink için
            } else {
                // Mevcut konuşma yoksa, yeni bir konuşma başlat
                if let conversationId = await viewModel.startNewConversation(with: userId, initialMessage: nil) {
                    // Yeni konuşma başarıyla oluşturulduysa ChatView'a git
                    // selectedUserId NavigationLink'i tetikleyecek.
                    // Bu gecikme, loadConversations'ın tamamlanıp UI'ın güncellenmesi için eklendi.
                    // Daha iyi bir çözüm, Combine veya async/await ile state güncellemelerini yönetmek olabilir.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                         selectedUserId = conversationId
                    }
                } else {
                    // Hata durumunu kullanıcıya bildir
                    print("Error starting new conversation with user: \(userId)")
                    // Burada kullanıcıya bir uyarı gösterilebilir.
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
            HStack(spacing: 12) {
                // Profil fotoğrafı
                if let imageUrl = user.profileImageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(user.username.prefix(1).uppercased())
                                .foregroundColor(.white)
                                .font(.headline)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "message")
                    .foregroundColor(.blue)
                    .font(.headline)
            }
            .padding(.vertical, 8)
        }
    }
} 
import SwiftUI
import Firebase

// Yeni mesaj oluşturma ekranı
struct NewMessageView: View {
    @ObservedObject var viewModel: DirectMessageViewModel
    @Environment(\.presentationMode) var presentationMode
    // @State private var searchText = "" // ViewModel'den userSearchText kullanılacak
    @State private var selectedUserId: String? = nil
    // @State private var newMessageText = "" // Bu görünümde mesaj yazılmıyor, ChatView'da yazılacak
    @State private var isShowingChatView = false
    @State private var createdConversationId: String? = nil
    
    // Başlangıçta seçilen kullanıcı
    var initialSelectedUserId: String? = nil
    
    init(viewModel: DirectMessageViewModel, initialSelectedUserId: String? = nil) {
        self.viewModel = viewModel
        // Eğer başlangıçta bir kullanıcı ID'si geldiyse, onu selectedUserId'ye ata
        // Ancak bu atamayı .onAppear içinde yapmak daha güvenli olabilir, viewModel henüz tam yüklenmemiş olabilir.
        self.initialSelectedUserId = initialSelectedUserId
        // viewModel.userSearchText = "" // Görünüm her açıldığında arama metnini sıfırla
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Başlık
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("İptal")
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text("Yeni Mesaj")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // "İleri" butonu sadece bir kullanıcı seçildiğinde aktif olmalı
                        Button(action: {
                            if let receiverId = selectedUserId {
                                Task {
                                    // Önce mevcut bir konuşma var mı diye bak, yoksa yeni konuşma başlat.
                                    // Bu mantık ChatView'a veya startNewConversation'a taşınabilir.
                                    // Şimdilik doğrudan ChatView'a yönlendireceğiz, ChatView içinde konuşma yoksa oluşturulacak.
                                    createdConversationId = await viewModel.startNewConversation(with: receiverId, initialMessage: nil)
                                    if createdConversationId != nil {
                                        isShowingChatView = true
                                    }
                                }
                            }
                        }) {
                            Text("İleri")
                                .foregroundColor(selectedUserId != nil ? .blue : .blue.opacity(0.5))
                        }
                        .disabled(selectedUserId == nil)
                        
                        // ChatView'a yönlendirme
                        // NavigationLink'i Button'ın dışına alarak görünmez yapıyoruz.
                        // isShowingChatView true olduğunda otomatik olarak tetiklenecek.
                        NavigationLink(
                            destination: ChatView(conversationId: createdConversationId ?? "", viewModel: viewModel),
                            isActive: $isShowingChatView
                        ) {
                            EmptyView()
                        }
                        
                    }
                    .padding()
                    
                    // Arama alanı
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        
                        TextField("Ara", text: $viewModel.userSearchText) // ViewModel'deki userSearchText'e bağla
                            .foregroundColor(.white)
                            .padding(8)
                        
                        if !viewModel.userSearchText.isEmpty {
                            Button(action: {
                                viewModel.userSearchText = "" // ViewModel'deki metni temizle
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
                    
                    Text("Kime:")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Kullanıcı listesi
                    if viewModel.userSearchText.isEmpty && viewModel.followingUsers.isEmpty && initialSelectedUserId == nil {
                        // Arama yapılmamışsa, öneri yoksa ve dışarıdan bir kullanıcı seçilmemişse
                        // Veya takip edilen kullanıcıları burada da gösterebiliriz (isteğe bağlı)
                        Text("Takip ettiğin kişileri veya kullanıcı adını arayarak mesaj gönderebilirsin.")
                            .foregroundColor(.gray)
                            .padding()
                            .multilineTextAlignment(.center)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                // Aranan kullanıcıları veya başlangıçta seçilen kullanıcıyı göster
                                // initialSelectedUserId varsa ve arama metni boşsa, sadece o kullanıcıyı (eğer bulunursa) göstermek bir seçenek olabilir.
                                // Ya da arama metni boşken takip edilenleri göstermeye devam edebiliriz.
                                ForEach(viewModel.userSearchText.isEmpty ? viewModel.followingUsers : viewModel.searchedUsers) { user in
                                    // Mevcut kullanıcıyı listede gösterme
                                    if user.id != viewModel.userId {
                                        Button(action: {
                                            selectedUserId = user.id
                                        }) {
                                            HStack {
                                                // Profil fotoğrafı (AsyncImage veya Kingfisher kullanılabilir)
                                                if let imageUrl = user.profileImageUrl, let url = URL(string: imageUrl) {
                                                    AsyncImage(url: url) {
                                                        $0.resizable().scaledToFill()
                                                    } placeholder: {
                                                        ProgressView()
                                                    }
                                                    .frame(width: 40, height: 40)
                                                    .clipShape(Circle())
                                                } else {
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.5))
                                                        .frame(width: 40, height: 40)
                                                        .overlay(
                                                            Text(String(user.username.prefix(1)).uppercased())
                                                                .font(.headline)
                                                                .foregroundColor(.white)
                                                        )
                                                }
                                                
                                                Text(user.username)
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                                
                                                if selectedUserId == user.id {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            .padding(.horizontal)
                                            .padding(.vertical, 8)
                                        }
                                        
                                        Divider()
                                            .background(Color.gray.opacity(0.3))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.userSearchText = "" // Görünüm açıldığında arama metnini temizle
                if let initialId = initialSelectedUserId {
                    selectedUserId = initialId
                    // Eğer initialId varsa ve bu kullanıcı takip edilenler listesinde yoksa,
                    // bu kullanıcıyı getirmek için özel bir API çağrısı gerekebilir veya
                    // arama metnine bu kullanıcının adını yazıp arama başlatılabilir.
                    // Şimdilik sadece ID atanıyor.
                } else {
                    // Eğer başlangıçta seçili kullanıcı yoksa ve arama metni boşsa, takip edilenleri yükle
                    if viewModel.userSearchText.isEmpty && viewModel.followingUsers.isEmpty {
                        Task {
                           await viewModel.loadFollowingUsers()
                        }
                    }
                }
            }
        }
    }
} 
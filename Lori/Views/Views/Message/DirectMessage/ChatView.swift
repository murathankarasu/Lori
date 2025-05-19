import SwiftUI
import Firebase

// Sohbet ekranı
struct ChatView: View {
    let conversationId: String
    @ObservedObject var viewModel: DirectMessageViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Başlık
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("Kullanıcı") // Gerçek uygulamada karşı kullanıcının adı
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive, action: {
                            deleteConversation()
                        }) {
                            Label("Sohbeti Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                
                // Mesaj listesi
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if viewModel.currentConversationMessages.isEmpty {
                    Spacer()
                    Text("Henüz mesaj yok")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollViewReader { scrollView in
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.currentConversationMessages) { message in
                                    MessageBubble(message: message, isFromCurrentUser: message.senderId == viewModel.userId)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .onChange(of: viewModel.currentConversationMessages.count) { _ in
                            if let lastMessage = viewModel.currentConversationMessages.last {
                                withAnimation {
                                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Mesaj gönderme alanı
                HStack {
                    TextField("Mesaj...", text: $viewModel.newMessageText)
                        .padding(10)
                        .background(Color(UIColor.darkGray).opacity(0.3))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(viewModel.newMessageText.isEmpty ? .gray : .blue)
                            .padding(10)
                    }
                    .disabled(viewModel.newMessageText.isEmpty)
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadMessages(for: conversationId)
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
    
    private func deleteConversation() {
        Task {
            await viewModel.deleteConversation(conversationId)
            presentationMode.wrappedValue.dismiss()
        }
    }
} 

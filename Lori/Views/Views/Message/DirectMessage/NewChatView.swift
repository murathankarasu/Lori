import SwiftUI
import Firebase

// Yeni sohbet oluşturma ekranı
struct NewChatView: View {
    let userId: String
    @ObservedObject var viewModel: DirectMessageViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var messageText = ""
    
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
                    
                    Text("Yeni Mesaj")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Mesaj alanı
                HStack {
                    TextField("Mesaj...", text: $messageText)
                        .padding(10)
                        .background(Color(UIColor.darkGray).opacity(0.3))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                            .padding(10)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
    }
    
    private func sendMessage() {
        Task {
            if let conversationId = await viewModel.startNewConversation(
                with: userId,
                initialMessage: messageText
            ) {
                // Konuşma başarıyla oluşturuldu ve ilk mesaj gönderildi
                messageText = ""
                // Tüm sheet'leri kapatıp ana ekrana dönmek için
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
} 
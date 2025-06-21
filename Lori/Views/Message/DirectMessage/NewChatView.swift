import SwiftUI
import Firebase

// New chat creation screen
struct NewChatView: View {
    let userId: String
    @ObservedObject var viewModel: DirectMessageViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var messageText = ""
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("New Message")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Message field
                HStack {
                    TextField("Message...", text: $messageText)
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
                // Conversation successfully created and first message sent
                messageText = ""
                // Close all sheets and return to main screen
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
} 
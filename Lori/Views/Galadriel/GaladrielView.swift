import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GaladrielView: View {
    @StateObject private var viewModel = GaladrielViewModel()
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var glowAmount: CGFloat = 0.0
    @State private var typingDots = 1
    @State private var username: String = ""
    
    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    let typingTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    private let gradientColors = [
        Color.white,
        Color.purple.opacity(0.8),
        Color.purple.opacity(0.6)
    ]
    
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.purple.opacity(0.1),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all, edges: .top)
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Spacer()
                    
                    Text("Galadriel")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.white, .purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .white.opacity(glowAmount), radius: 10, x: 0, y: 0)
                        .onReceive(timer) { _ in
                            withAnimation(.easeInOut(duration: 1.5)) {
                                glowAmount = glowAmount == 0.0 ? 0.8 : 0.0
                            }
                        }
                    
                    Spacer()
                }
                .padding()
                .padding(.top, 10)
                .background(Color.black.opacity(0.8))
                .zIndex(1)
                
                // Chat area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            if isLoading {
                                HStack {
                                    Text(String(repeating: ".", count: typingDots))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.purple.opacity(0.2))
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                        .onReceive(typingTimer) { _ in
                                            withAnimation {
                                                typingDots = typingDots >= 3 ? 1 : typingDots + 1
                                            }
                                        }
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding()
                        .padding(.bottom, 10)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message input area
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.purple.opacity(0.3))
                    
                    HStack(spacing: 12) {
                        TextField("Type your message...", text: $messageText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.purple.opacity(0.15))
                            .cornerRadius(24)
                            .foregroundColor(.white)
                            .accentColor(.white)
                        
                        Button(action: sendMessage) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(
                                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.3)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ) :
                                            LinearGradient(
                                                gradient: Gradient(colors: [.white, .purple.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .black)
                                }
                            }
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear(perform: fetchUsername)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func fetchUsername() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data(), let uname = data["username"] as? String {
                username = uname
            }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        let userMessage = Message(id: UUID().uuidString, content: trimmedMessage, isUser: true)
        viewModel.messages.append(userMessage)
        messageText = ""
        
        isLoading = true
        
        Task {
            await viewModel.sendMessage(trimmedMessage, username: username)
            isLoading = false
        }
    }
}

struct MessageBubbleView: View {
    let message: Message
    
    private let gradientColors = [
        Color.white,
        Color.purple.opacity(0.8),
        Color.purple.opacity(0.6)
    ]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isUser ?
                        LinearGradient(
                            gradient: Gradient(colors: [.white, .purple.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.2), Color.purple.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(
                        message.isUser ? Color.black : Color.white
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding(message.isUser ? .leading : .trailing, 40)
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }
}

struct GaladrielView_Previews: PreviewProvider {
    static var previews: some View {
        GaladrielView()
    }
} 
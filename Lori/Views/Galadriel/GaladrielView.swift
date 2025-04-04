import SwiftUI

struct GaladrielView: View {
    @StateObject private var viewModel = GaladrielViewModel()
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var showDebugLogs = false
    @State private var glowAmount: CGFloat = 0.0
    @State private var typingDots = 1
    
    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    let typingTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Üst bar
                    HStack {
                        Button(action: { showDebugLogs.toggle() }) {
                            Image(systemName: "terminal")
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("GALADRIEL")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(glowAmount), radius: 10, x: 0, y: 0)
                            .onReceive(timer) { _ in
                                withAnimation(.easeInOut(duration: 1.5)) {
                                    glowAmount = glowAmount == 0.0 ? 0.8 : 0.0
                                }
                            }
                        
                        Spacer()
                        
                        Image(systemName: "terminal")
                            .foregroundColor(.clear)
                    }
                    .padding()
                    
                    if showDebugLogs {
                        // Debug logları
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.debugLogs, id: \.self) { log in
                                    Text(log)
                                        .font(.system(.footnote, design: .monospaced))
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                        }
                        .background(Color.black.opacity(0.8))
                    } else {
                        // Sohbet alanı
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubbleView(message: message)
                                }
                                
                                if isLoading {
                                    HStack {
                                        Text(String(repeating: ".", count: typingDots))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color.gray.opacity(0.3))
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
                        }
                    }
                    
                    // Mesaj gönderme alanı
                    HStack(spacing: 12) {
                        TextField("Bir mesaj yazın...", text: $messageText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                            .accentColor(.white)
                        
                        Button(action: sendMessage) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
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
            await viewModel.sendMessage(trimmedMessage)
            isLoading = false
        }
    }
}

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    message.isUser ? Color.white : Color.gray.opacity(0.3)
                )
                .foregroundColor(
                    message.isUser ? Color.black : Color.white
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.clear, lineWidth: 0)
                )
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
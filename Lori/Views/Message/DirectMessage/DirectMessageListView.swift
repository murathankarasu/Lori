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
                    // Header
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
                        
                        Text("Messages")
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
                    
                    // Search field
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                        
                        ZStack(alignment: .leading) {
                            if searchText.isEmpty {
                                Text("Search messages")
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
                        // Show followed accounts
                        if viewModel.followingUsers.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "message.circle")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray.opacity(0.6))
                                
                                Text("No messages yet")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("Start messaging with your friends")
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    showingNewMessageView = true
                                }) {
                                    Text("Send Message")
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
                                    Text("Start messaging")
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
                        // Conversation list
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.filteredConversations) { conversation in
                                    Button(action: {
                                        // Set clicked conversation
                                        selectedConversationId = conversation.id
                                        
                                        // Preload messages
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
                // NavigationLink for ChatView
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
    
    // Setup notification observer
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenDirectMessageWithUser"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let userId = userInfo["userId"] as? String {
                // Automatically open new message screen when user ID is received
                selectedFollowingUserId = userId
                showingNewMessageView = true
            }
        }
    }
    
    // Start new chat with selected user or go to existing chat
    private func showChat(with userId: String) {
        Task {
            // Check if there's an existing conversation with the user
            if let existingConversation = viewModel.conversations.first(where: { $0.users.contains(userId) && $0.users.contains(viewModel.userId) }) {
                // If existing conversation exists, load messages
                if let conversationId = existingConversation.id {
                    await viewModel.loadMessages(for: conversationId)
                    
                    // Update UI on main thread to navigate to ChatView
                    DispatchQueue.main.async {
                        selectedConversationId = conversationId
                    }
                }
            } else {
                // If no existing conversation, start a new conversation
                if let conversationId = await viewModel.startNewConversation(with: userId, initialMessage: "Hello") {
                    // Load new messages
                    await viewModel.loadMessages(for: conversationId)
                    
                    // Update UI on main thread to navigate to ChatView
                    DispatchQueue.main.async {
                        selectedConversationId = conversationId
                    }
                }
            }
        }
    }
}

// Suggested user row
struct SuggestedUserRow: View {
    let user: User
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Profile image - Kingfisher
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
                        Text("Send message")
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
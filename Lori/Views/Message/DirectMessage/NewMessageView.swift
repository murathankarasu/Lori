import SwiftUI
import Firebase
import Kingfisher

// New message creation screen
struct NewMessageView: View {
    @ObservedObject var viewModel: DirectMessageViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedUserId: String? = nil
    @State private var isShowingChatView = false
    @State private var createdConversationId: String? = nil
    @State private var navigateToChatScreen = false
    
    // Initially selected user
    var initialSelectedUserId: String? = nil
    
    init(viewModel: DirectMessageViewModel, initialSelectedUserId: String? = nil) {
        self.viewModel = viewModel
        self.initialSelectedUserId = initialSelectedUserId
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
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("New Message")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            if let receiverId = selectedUserId {
                                Task {
                                    // Send "Hello" as initial message
                                    let initialMessage = "Hello"
                                    createdConversationId = await viewModel.startNewConversation(with: receiverId, initialMessage: initialMessage)
                                    
                                    if let conversationId = createdConversationId {
                                        // Load messages after conversation is created
                                        await viewModel.loadMessages(for: conversationId)
                                        
                                        // Update UI on main thread
                                        DispatchQueue.main.async {
                                            navigateToChatScreen = true
                                            // Close modal screen after a short delay
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                presentationMode.wrappedValue.dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                        }) {
                            Text("Next")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(selectedUserId != nil ? .white : .gray)
                        }
                        .disabled(selectedUserId == nil)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    Divider()
                        .background(Color.gray.opacity(0.2))
                    
                    // Search field
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                        
                        ZStack(alignment: .leading) {
                            if viewModel.userSearchText.isEmpty {
                                Text("Search users")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 16))
                            }
                            
                            TextField("", text: $viewModel.userSearchText)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        if !viewModel.userSearchText.isEmpty {
                            Button(action: {
                                viewModel.userSearchText = ""
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
                    .padding(.vertical, 16)
                    
                    // To: label
                    HStack {
                        Text("To:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    
                    // Content section
                    ZStack {
                        if viewModel.isLoading {
                            // Loading indicator
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.white)
                                
                                Text("Searching...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if viewModel.userSearchText.isEmpty && viewModel.suggestedUsers.isEmpty && viewModel.followingUsers.isEmpty && initialSelectedUserId == nil {
                            // Empty state view
                            emptyStateView
                        } else if !viewModel.userSearchText.isEmpty && viewModel.searchedUsers.isEmpty {
                            // No results found
                            noResultsView
                        } else {
                            // User list
                            userListView
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Load followed and suggested users when component appears
                Task {
                    await viewModel.loadSuggestedUsers()
                    await viewModel.loadFollowingUsers()
                }
            }
            .background(
                NavigationLink(
                    destination: createdConversationId != nil ? ChatView(conversationId: createdConversationId!, viewModel: viewModel) : nil,
                    isActive: $navigateToChatScreen
                ) {
                    EmptyView()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("Send Message")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            Text("You can send messages to people you interact with most or by searching for a username.")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - No results found view
    private var noResultsView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                
                VStack(spacing: 8) {
                    Text("User not found")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Try searching with a different username, email, or user ID")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            // Suggested search terms
            VStack(spacing: 12) {
                Text("Search suggestions:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                VStack(spacing: 8) {
                    Text("• Try searching with the full username")
                    Text("• Use email address for better results")
                    Text("• Search with user ID")
                }
                .font(.system(size: 14))
                .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - User list view
    private var userListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Show search results if searching
                if !viewModel.userSearchText.isEmpty {
                    ForEach(viewModel.searchedUsers) { user in
                        if user.id != viewModel.userId {
                            userRow(user: user)
                            
                            if user.id != viewModel.searchedUsers.last?.id {
                                Divider()
                                    .background(Color.gray.opacity(0.2))
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                } else {
                    // Suggested users section
                    if !viewModel.suggestedUsers.isEmpty {
                        sectionHeader(title: "People You Interact With Most", subtitle: "People you've interacted with most")
                        
                        ForEach(viewModel.suggestedUsers) { user in
                            if user.id != viewModel.userId {
                                userRow(user: user, showInteractionBadge: true)
                                
                                if user.id != viewModel.suggestedUsers.last?.id {
                                    Divider()
                                        .background(Color.gray.opacity(0.2))
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    
                    // Followed users section
                    if !viewModel.followingUsers.isEmpty {
                        if !viewModel.suggestedUsers.isEmpty {
                            Divider()
                                .background(Color.gray.opacity(0.4))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                        }
                        
                        sectionHeader(title: "People You Follow", subtitle: "People you follow list")
                        
                        ForEach(viewModel.followingUsers) { user in
                            if user.id != viewModel.userId {
                                userRow(user: user)
                                
                                if user.id != viewModel.followingUsers.last?.id {
                                    Divider()
                                        .background(Color.gray.opacity(0.2))
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Helper Views
    
    // Section header
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // User row
    private func userRow(user: User, showInteractionBadge: Bool = false) -> some View {
        Button(action: {
            selectedUserId = user.id
        }) {
            HStack(spacing: 12) {
                // Profile image
                if let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                    KFImage(URL(string: profileImageUrl))
                        .setProcessor(RoundCornerImageProcessor(cornerRadius: 25))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                }
                
                // User information
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(user.username)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 12))
                        }
                        
                        if showInteractionBadge {
                            Text("Sık etkileşim")
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(user.email)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Selection indicator
                if selectedUserId == user.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                selectedUserId == user.id ? Color.white.opacity(0.1) : Color.clear
            )
        }
    }
} 
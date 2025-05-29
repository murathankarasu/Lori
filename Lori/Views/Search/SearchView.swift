import SwiftUI
import FirebaseFirestore
import Kingfisher

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Ana arka plan
                Color.black
                    .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Üst bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Search")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Boş alan (simetri için)
                    Color.clear
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Arama çubuğu
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    ZStack(alignment: .leading) {
                        if viewModel.searchText.isEmpty {
                            Text("Search by username, email or user ID")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        }
                        
                        TextField("", text: $viewModel.searchText)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // İçerik bölümü
                ZStack {
                    if viewModel.isLoading {
                        // Yükleme göstergesi
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                            
                            Text("Searching...")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.searchText.isEmpty {
                        // Son aramalar ve öneriler
                        recentSearchesAndSuggestionsView
                    } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                        // Sonuç bulunamadı
                        noResultsView
                    } else {
                        // Arama sonuçları
                        searchResultsView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .background(
            NavigationLink(
                destination: viewModel.selectedUserId != nil ? ProfileView(userId: viewModel.selectedUserId!) : nil,
                isActive: $viewModel.shouldNavigateToProfile
            ) {
                EmptyView()
            }
            .hidden()
        )
        }
    }
    
    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                
                VStack(spacing: 8) {
                    Text("No users found")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Try searching with a different username, email, or user ID")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            // Önerilen arama terimleri
            VStack(spacing: 12) {
                Text("Search suggestions:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                VStack(spacing: 8) {
                    Text("• Try searching by exact username")
                    Text("• Use email address for better results")
                    Text("• Search with complete user ID")
                }
                .font(.system(size: 14))
                .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Son aramalar ve öneriler görünümü
    private var recentSearchesAndSuggestionsView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 32) {
                // Son aramalar bölümü
                if !viewModel.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recent Searches")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("\(viewModel.recentSearches.count) recent searches")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button("Clear All") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.recentSearches.forEach { user in
                                        viewModel.removeRecentSearch(user)
                                    }
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.recentSearches) { user in
                                UserCell(user: user, onTap: {
                                    viewModel.navigateToProfile(user)
                                }, onRemove: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.removeRecentSearch(user)
                                    }
                                }, showRemoveButton: true)
                                
                                if user.id != viewModel.recentSearches.last?.id {
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                        .padding(.leading, 82)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                    }
                }
                
                // Eğer son aramalar yoksa
                if viewModel.recentSearches.isEmpty {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.circle")
                                .font(.system(size: 64, weight: .light))
                                .foregroundColor(.white.opacity(0.6))
                            
                            VStack(spacing: 8) {
                                Text("Discover People")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Search for users by their username, email, or user ID to connect with them.")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                            }
                        }
                        
                        // Özellik kartları
                        VStack(spacing: 12) {
                            FeatureCard(
                                icon: "person.circle",
                                title: "Username Search",
                                description: "Find users by their unique username"
                            )
                            
                            FeatureCard(
                                icon: "envelope.circle",
                                title: "Email Search",
                                description: "Search using email addresses"
                            )
                            
                            FeatureCard(
                                icon: "number.circle",
                                title: "User ID Search",
                                description: "Direct search with user ID"
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Arama sonuçları görünümü
    private var searchResultsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Sonuç başlığı
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Search Results")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(viewModel.searchResults.count) users found")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Arama terimi göstergesi
                    Text("'\(viewModel.searchText)'")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                
                // Sonuçlar
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.searchResults) { user in
                        UserCell(user: user, onTap: {
                            viewModel.navigateToProfile(user)
                        }, onRemove: nil, showRemoveButton: false)
                        
                        if user.id != viewModel.searchResults.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 82)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Kullanıcı Hücresi Komponenti
struct UserCell: View {
    let user: User
    let onTap: () -> Void
    let onRemove: (() -> Void)?
    let showRemoveButton: Bool
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack(spacing: 16) {
                // Profil fotoğrafı - Improved loading
                KFImage(URL(string: user.profileImageUrl ?? ""))
                    .cacheMemoryOnly(false)
                    .cacheOriginalImage()
                    .fade(duration: 0.2)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 108, height: 108)))
                    .loadDiskFileSynchronously()
                    .backgroundDecode()
                    .onProgress { receivedSize, totalSize in
                        // Progress handling if needed
                    }
                    .onSuccess { result in
                        // Success handling if needed
                    }
                    .onFailure { error in
                        print("Profile image load failed for user \(user.username): \(error)")
                    }
                    .placeholder {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.1),
                                            Color.white.opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 54, height: 54)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 54, height: 54)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    // Username ve doğrulama rozeti
                    HStack(spacing: 6) {
                        Text(user.username)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Bio
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Takipçi sayısı
                    if user.followers > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                            
                            Text("\(formatFollowerCount(user.followers)) followers")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Remove button
                if let onRemove = onRemove, showRemoveButton {
                    Button(action: {
                        onRemove()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Chevron for navigation
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatFollowerCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Feature Card Component
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

#Preview {
    SearchView()
} 
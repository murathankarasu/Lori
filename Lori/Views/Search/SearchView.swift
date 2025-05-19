import SwiftUI
import FirebaseFirestore
import Kingfisher

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Arama çubuğu
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search users...", text: $viewModel.searchText)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // İçerik bölümü
                    ZStack {
                        if viewModel.isLoading {
                            // Yükleme göstergesi
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black)
                        } else if viewModel.searchText.isEmpty {
                            // Son aramalar
                            recentSearchesView
                        } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                            // Sonuç bulunamadı
                            VStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("No results found")
                                    .foregroundColor(.gray)
                                    .font(.headline)
                                Text("Try searching for a different username")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // Arama sonuçları
                            searchResultsView
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Son aramalar görünümü
    private var recentSearchesView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Recent Searches")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Tüm aramaları temizleme butonu
                if !viewModel.recentSearches.isEmpty {
                    Button("Clear All") {
                        // Bu kısmı içinde hepsi temizlenecek
                        viewModel.recentSearches.forEach { user in
                            viewModel.removeRecentSearch(user)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            if viewModel.recentSearches.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No Searches Yet")
                        .foregroundColor(.gray)
                        .font(.headline)
                    Text("Your recent searches will appear here.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 50)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.recentSearches) { user in
                            UserCell(user: user, onTap: {
                                viewModel.userProfileTapped(user)
                            }, onRemove: {
                                viewModel.removeRecentSearch(user)
                            }, showRemoveButton: true)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Arama sonuçları görünümü
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.searchResults) { user in
                    UserCell(user: user, onTap: {
                        viewModel.userProfileTapped(user)
                    }, onRemove: nil, showRemoveButton: false)
                }
            }
        }
        .padding(.top, 10)
    }
}

// MARK: - Kullanıcı Hücresi Komponenti
struct UserCell: View {
    let user: User
    let onTap: () -> Void
    let onRemove: (() -> Void)?
    let showRemoveButton: Bool
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Kingfisher ile profil fotoğrafı
                KFImage(URL(string: user.profileImageUrl ?? ""))
                    .cacheMemoryOnly(false)
                    .cacheOriginalImage()
                    .fade(duration: 0.25)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 80, height: 80)))
                    .loadDiskFileSynchronously()
                    .placeholder {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .aspectRatio(contentMode: .fill)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(user.username)
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .foregroundColor(.gray)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if let onRemove = onRemove, showRemoveButton {
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.black)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SearchView()
} 
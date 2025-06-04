import SwiftUI

struct SearchContentView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                SearchLoadingView()
            } else if viewModel.searchText.isEmpty {
                RecentSearchesView(viewModel: viewModel)
            } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                NoResultsView()
            } else {
                SearchResultsView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search Loading View
struct SearchLoadingView: View {
    @State private var typingDots = 1
    let typingTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            
            Text("Searching...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - No Results View
struct NoResultsView: View {
    var body: some View {
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
            
            // Search suggestions
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
} 
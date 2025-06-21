import SwiftUI

struct RecentSearchesView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 32) {
                // Recent searches section
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
                
                // If no recent searches
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
                        
                        // Feature cards
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
} 
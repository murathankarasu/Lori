import SwiftUI

struct SearchResultsView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Results header
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
                    
                    // Search term indicator
                    Text("'\(viewModel.searchText)'")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                
                // Results
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
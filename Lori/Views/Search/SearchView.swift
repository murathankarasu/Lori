import SwiftUI
import FirebaseFirestore
import Kingfisher

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main background
                Color.black
                    .ignoresSafeArea(.all)
            
                VStack(spacing: 0) {
                    // Top bar
                    SearchTopBarView(dismiss: dismiss)
                    
                    // Search bar
                    SearchBarView(searchText: $viewModel.searchText)
                    
                    // Content section
                    SearchContentView(viewModel: viewModel)
                }
                
                // Hidden NavigationLink for profile navigation
                NavigationLink(
                    destination: Group {
                        if let userId = viewModel.selectedUserId {
                            ProfileView(userId: userId)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: $viewModel.shouldNavigateToProfile
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Reset navigation state when view appears
            viewModel.resetNavigation()
        }
        .onChange(of: viewModel.shouldNavigateToProfile) { isNavigating in
            // Reset navigation after navigation completes
            if !isNavigating {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.resetNavigation()
                }
            }
        }
    }
}

#Preview {
    SearchView()
} 
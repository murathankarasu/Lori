import SwiftUI
import FirebaseFirestore

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
                        
                        TextField("Kullanıcı ara...", text: $viewModel.searchText)
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
                    
                    if viewModel.searchText.isEmpty {
                        // Son aramalar
                        VStack(alignment: .leading) {
                            Text("Son Aramalar")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(viewModel.recentSearches) { user in
                                        NavigationLink(destination: ProfileView(userId: user.id)) {
                                            HStack {
                                                AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                } placeholder: {
                                                    Image(systemName: "person.circle.fill")
                                                        .resizable()
                                                        .foregroundColor(.gray)
                                                }
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                                
                                                VStack(alignment: .leading) {
                                                    Text(user.username)
                                                        .foregroundColor(.white)
                                                        .font(.headline)
                                                }
                                                
                                                Spacer()
                                                
                                                Button(action: {
                                                    viewModel.removeRecentSearch(user)
                                                }) {
                                                    Image(systemName: "xmark")
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .padding()
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        // Arama sonuçları
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.searchResults) { user in
                                    NavigationLink(destination: ProfileView(userId: user.id)) {
                                        HStack {
                                            AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Image(systemName: "person.circle.fill")
                                                    .resizable()
                                                    .foregroundColor(.gray)
                                            }
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                            
                                            VStack(alignment: .leading) {
                                                Text(user.username)
                                                    .foregroundColor(.white)
                                                    .font(.headline)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    SearchView()
} 
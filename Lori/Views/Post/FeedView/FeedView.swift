import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FeedView: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedTab = 0
    @State private var showCreatePost = false
    @State private var showPostDetail = false
    @State private var selectedPost: Post?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeaturedFeedView(selectedPost: $selectedPost, showPostDetail: $showPostDetail)
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Öne Çıkanlar")
                }
                .tag(0)
            
            FollowingFeedView(selectedPost: $selectedPost, showPostDetail: $showPostDetail)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Takip")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profil")
                }
                .tag(2)
            
            SettingsView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Ayarlar")
                }
                .tag(3)
        }
        .tint(.white)
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
        .sheet(isPresented: $showPostDetail) {
            if let post = selectedPost {
                PostDetailView(post: post)
            }
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(isLoggedIn: .constant(true))
    }
} 
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FeedView: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedTab = 0
    @State private var showCreatePost = false
    @State private var showPostDetail = false
    @State private var selectedPost: Post?
    
    init(isLoggedIn: Binding<Bool>) {
        self._isLoggedIn = isLoggedIn
        
        // TabBar'ın görünümünü özelleştirme
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        
        // Normal durum için renkleri ayarla
        appearance.stackedLayoutAppearance.normal.iconColor = .gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        
        // Seçili durum için renkleri ayarla
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        // Scroll edildiğinde de aynı görünümü koru
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            TabView(selection: $selectedTab) {
                FeaturedFeedView(selectedPost: $selectedPost, showPostDetail: $showPostDetail)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        Text("Öne Çıkanlar")
                    }
                    .tag(0)
                
                FollowingFeedView(selectedPost: $selectedPost, showPostDetail: $showPostDetail)
                    .tabItem {
                        Image(systemName: selectedTab == 1 ? "person.2.fill" : "person.2")
                        Text("Takip")
                    }
                    .tag(1)
                
                ProfileView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                        Text("Profil")
                    }
                    .tag(2)
                
                GaladrielView()
                    .tabItem {
                        Image(systemName: selectedTab == 3 ? "wand.and.stars.inverse" : "wand.and.stars")
                        Text("Galadriel")
                    }
                    .tag(3)
                
                SettingsView(isLoggedIn: $isLoggedIn)
                    .tabItem {
                        Image(systemName: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                        Text("Ayarlar")
                    }
                    .tag(4)
            }
            .accentColor(.white)
        }
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

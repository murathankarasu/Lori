import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UIKit

struct FeedView: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedTab = 0
    @State private var showCreatePost = false
    @State private var showPostDetail = false
    @State private var selectedPost: Post?
    @State private var username: String = ""
    @State private var showMessages = false
    
    var body: some View {
        CustomTabBarView(
            username: $username,
            selectedPost: $selectedPost,
            showPostDetail: $showPostDetail,
            isLoggedIn: $isLoggedIn
        )
        .edgesIgnoringSafeArea(.all)
        .onAppear(perform: fetchUsername)
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
        .fullScreenCover(isPresented: $showPostDetail) {
            if let post = selectedPost {
                PostDetailView(post: post)
            }
        }
    }
    
    private func fetchUsername() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data(), let uname = data["username"] as? String {
                username = uname
            }
        }
    }
}

struct CustomTabBarView: UIViewControllerRepresentable {
    @Binding var username: String
    @Binding var selectedPost: Post?
    @Binding var showPostDetail: Bool
    @Binding var isLoggedIn: Bool
    
    func makeUIViewController(context: Context) -> UITabBarController {
        let tabBarController = UITabBarController()
        
        // Tab bar görünümünü özelleştir
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        
        // Normal durum için renkleri ayarla
        appearance.stackedLayoutAppearance.normal.iconColor = .gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        
        // Seçili durum için renkleri ayarla
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance
        tabBarController.tabBar.itemSpacing = 0 // Küçült
        tabBarController.tabBar.itemWidth = UIScreen.main.bounds.width / 5 // 5 sekme için
        tabBarController.tabBar.itemPositioning = .fill // Sekmeleri yayarak doldur
        
        // Sekmeleri oluştur
        let viewControllers = [
            createViewController(for: 0), // Keşfet
            createViewController(for: 1), // Takip
            createViewController(for: 2), // Profil
            createViewController(for: 3), // Post Cast
            createViewController(for: 4)  // Galadriel
        ]
        
        tabBarController.viewControllers = viewControllers
        tabBarController.selectedIndex = 0
        tabBarController.delegate = context.coordinator
        
        // "More" sekmesinin oluşturulmasını engelle
        tabBarController.moreNavigationController.isNavigationBarHidden = true
        tabBarController.customizableViewControllers = nil
        
        return tabBarController
    }
    
    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
        // Güncellemeleri işle
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Sekme ikonlarını ve başlıklarını ayarla
    private func createViewController(for index: Int) -> UIViewController {
        let hostingController = UIHostingController(rootView: getTabView(for: index))
        hostingController.view.backgroundColor = .black
        
        let tabBarItem = UITabBarItem()
        switch index {
        case 0:
            tabBarItem.image = UIImage(systemName: "house")
            tabBarItem.selectedImage = UIImage(systemName: "house.fill")
            tabBarItem.title = "Keşfet"
        case 1:
            tabBarItem.image = UIImage(systemName: "person.2")
            tabBarItem.selectedImage = UIImage(systemName: "person.2.fill")
            tabBarItem.title = "Takip"
        case 2:
            tabBarItem.image = UIImage(systemName: "person")
            tabBarItem.selectedImage = UIImage(systemName: "person.fill")
            tabBarItem.title = "Profil"
        case 3:
            tabBarItem.image = UIImage(systemName: "mic")
            tabBarItem.selectedImage = UIImage(systemName: "mic.fill")
            tabBarItem.title = "Post Cast"
        case 4:
            tabBarItem.image = UIImage(systemName: "wand.and.stars")
            tabBarItem.selectedImage = UIImage(systemName: "wand.and.stars.inverse")
            tabBarItem.title = "Galadriel"
        default:
            break
        }
        
        hostingController.tabBarItem = tabBarItem
        return hostingController
    }
    
    // Sekme için içerik görünümünü seç
    private func getTabView(for index: Int) -> some View {
        switch index {
        case 0:
            return AnyView(FeaturedFeedView(selectedPost: $selectedPost, showPostDetail: $showPostDetail))
        case 1:
            return AnyView(FollowingFeedView(selectedPost: $selectedPost, showPostDetail: $showPostDetail))
        case 2:
            return AnyView(ProfileView(userId: Auth.auth().currentUser?.uid ?? ""))
        case 3:
            return AnyView(PodcastView(userID: Auth.auth().currentUser?.uid ?? "", username: username))
        case 4:
            return AnyView(GaladrielView())
        default:
            return AnyView(Text("Invalid Tab"))
        }
    }
    
    class Coordinator: NSObject, UITabBarControllerDelegate {
        var parent: CustomTabBarView
        
        init(_ parent: CustomTabBarView) {
            self.parent = parent
        }
        
        func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            // Gerekirse sekme değişikliklerini işle
        }
    }
}

// Geçici Mesaj Görünümü
struct MessagesPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image(systemName: "message")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                Text("Messaging Coming Soon")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("This feature is under development")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(isLoggedIn: .constant(true))
    }
}

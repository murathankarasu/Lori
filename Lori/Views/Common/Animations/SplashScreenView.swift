import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var isFirstLaunch: Bool = true
    
    var body: some View {
        NavigationStack {
            if isActive {
                ContentView()
                    .navigationBarBackButtonHidden(true)
            } else {
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        if isFirstLaunch {
                            Text("Hello")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(size)
                                .opacity(opacity)
                        } else {
                            Image("loginlogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .scaleEffect(size)
                                .opacity(opacity)
                        }
                    }
                }
                .onAppear {
                    // Check first launch
                    isFirstLaunch = UserDefaults.standard.bool(forKey: "isFirstLaunch")
                    
                    // Start preloading images in background immediately
                    Task {
                        await CacheManager.shared.preloadImages()
                    }
                    
                    // Animate logo/text
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                    
                    // Show splash screen for 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
                .onAppear {
                    // Update first launch value
                    if isFirstLaunch {
                        UserDefaults.standard.set(false, forKey: "isFirstLaunch")
                    }
                }
            }
        }
    }
}

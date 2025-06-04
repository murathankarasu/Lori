import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoadingView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @Binding var isPresented: Bool
    @Binding var isLoggedIn: Bool
    var onFinish: () -> Void
    
    let username: String
    
    init(isPresented: Binding<Bool>, isLoggedIn: Binding<Bool>, onFinish: @escaping () -> Void, username: String) {
        self._isPresented = isPresented
        self._isLoggedIn = isLoggedIn
        self.onFinish = onFinish
        self.username = username
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Image("loginlogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .opacity(opacity)
                    .scaleEffect(scale)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                opacity = 1
                scale = 1
            }
            
            // After animation, proceed to main app
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isPresented = false
                onFinish()
            }
        }
    }
} 
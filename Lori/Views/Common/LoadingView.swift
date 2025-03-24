import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoadingView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @Binding var isPresented: Bool
    @State private var shouldShowInterests = false
    var onFinish: () -> Void
    
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
            
            checkUserInterests()
        }
        .fullScreenCover(isPresented: $shouldShowInterests, onDismiss: {
            isPresented = false
            onFinish()
        }) {
            InterestsView()
        }
    }
    
    private func checkUserInterests() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let hasSelectedInitialInterests = document.data()?["hasSelectedInitialInterests"] as? Bool ?? false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if hasSelectedInitialInterests {
                        // İlgi alanları daha önce seçilmişse direkt FeedView'a git
                        isPresented = false
                        onFinish()
                    } else {
                        // İlgi alanları seçilmemişse InterestsView'ı göster
                        shouldShowInterests = true
                    }
                }
            }
        }
    }
} 
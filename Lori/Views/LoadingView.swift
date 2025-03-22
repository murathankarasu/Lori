import SwiftUI

struct LoadingView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @Binding var isPresented: Bool
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
            // Fade in animasyonu
            withAnimation(.easeIn(duration: 1.0)) {
                opacity = 1
                scale = 1
            }
            
            // 2 saniye bekle
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // Fade out animasyonu
                withAnimation(.easeOut(duration: 1.0)) {
                    opacity = 0
                    scale = 0.8
                }
                
                // Animasyon bittikten sonra
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    isPresented = false
                    onFinish()
                }
            }
        }
    }
} 
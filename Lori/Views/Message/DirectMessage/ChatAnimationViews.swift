import SwiftUI

// MARK: - Chat Animation Views

// Sohbet baloncukları yükselen animasyon 
struct ChatBubbleLoadingAnimation: View {
    @State private var bubbleScale1: CGFloat = 0.1
    @State private var bubbleScale2: CGFloat = 0.1
    @State private var bubbleScale3: CGFloat = 0.1
    @State private var bubbleOpacity1: Double = 0
    @State private var bubbleOpacity2: Double = 0
    @State private var bubbleOpacity3: Double = 0
    @State private var bubbleOffset1: CGFloat = 0
    @State private var bubbleOffset2: CGFloat = 0
    @State private var bubbleOffset3: CGFloat = 0
    @State private var horizontalOffset1: CGFloat = 0
    @State private var horizontalOffset2: CGFloat = 0
    @State private var horizontalOffset3: CGFloat = 0
    @State private var rotation1: Double = -5
    @State private var rotation2: Double = 5
    @State private var rotation3: Double = -5
    @State private var isAnimating = false
    @State private var animationCount = 0
    
    // Toplam animasyon süresi (saniye)
    let totalAnimationDuration: Double = 4.0
    
    let bubble1Delay = 0.0
    let bubble2Delay = 0.7
    let bubble3Delay = 1.4
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                // Sohbet baloncukları
                VStack {
                    HStack(spacing: 20) {
                        // Sol baloncuk (gelen mesaj)
                        LoadingBubbleShape(isFromCurrentUser: false)
                            .fill(Color.gray.opacity(0.7))
                            .frame(width: 60, height: 40)
                            .scaleEffect(bubbleScale1)
                            .opacity(bubbleOpacity1)
                            .offset(x: horizontalOffset1, y: bubbleOffset1)
                            .rotationEffect(.degrees(rotation1))
                            .blur(radius: bubbleOpacity1 * 2)
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    HStack(spacing: 20) {
                        Spacer()
                        
                        // Sağ baloncuk (giden mesaj)
                        LoadingBubbleShape(isFromCurrentUser: true)
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 70, height: 45)
                            .scaleEffect(bubbleScale2)
                            .opacity(bubbleOpacity2)
                            .offset(x: horizontalOffset2, y: bubbleOffset2)
                            .rotationEffect(.degrees(rotation2))
                            .blur(radius: bubbleOpacity2 * 2)
                    }
                    .padding(.vertical, 10)
                    
                    HStack(spacing: 20) {
                        // Sol baloncuk (gelen mesaj)
                        LoadingBubbleShape(isFromCurrentUser: false)
                            .fill(Color.gray.opacity(0.7))
                            .frame(width: 80, height: 50)
                            .scaleEffect(bubbleScale3)
                            .opacity(bubbleOpacity3)
                            .offset(x: horizontalOffset3, y: bubbleOffset3)
                            .rotationEffect(.degrees(rotation3))
                            .blur(radius: bubbleOpacity3 * 2)
                        
                        Spacer()
                    }
                }
            }
            .frame(height: 200)
            
            Text("Preparing Your Chat")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .opacity(isAnimating ? 1 : 0.7)
                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // İlk baloncuk animasyonu
        withAnimation(Animation.easeOut(duration: 2.0).delay(bubble1Delay).repeatForever(autoreverses: false)) {
            bubbleScale1 = 1.0
            bubbleOpacity1 = 0.8
            bubbleOffset1 = -100
            horizontalOffset1 = 10
            rotation1 = 5
        }
        
        withAnimation(Animation.easeOut(duration: 2.5).delay(bubble1Delay + 1.3).repeatForever(autoreverses: false)) {
            bubbleOpacity1 = 0
            horizontalOffset1 = 20
        }
        
        // İkinci baloncuk animasyonu
        withAnimation(Animation.easeOut(duration: 2.0).delay(bubble2Delay).repeatForever(autoreverses: false)) {
            bubbleScale2 = 1.0
            bubbleOpacity2 = 0.8
            bubbleOffset2 = -100
            horizontalOffset2 = -15
            rotation2 = -8
        }
        
        withAnimation(Animation.easeOut(duration: 2.5).delay(bubble2Delay + 1.3).repeatForever(autoreverses: false)) {
            bubbleOpacity2 = 0
            horizontalOffset2 = -25
        }
        
        // Üçüncü baloncuk animasyonu
        withAnimation(Animation.easeOut(duration: 2.0).delay(bubble3Delay).repeatForever(autoreverses: false)) {
            bubbleScale3 = 1.0
            bubbleOpacity3 = 0.8
            bubbleOffset3 = -100
            horizontalOffset3 = 15
            rotation3 = 8
        }
        
        withAnimation(Animation.easeOut(duration: 2.5).delay(bubble3Delay + 1.3).repeatForever(autoreverses: false)) {
            bubbleOpacity3 = 0
            horizontalOffset3 = 30
        }
    }
}

// Mesaj baloncuğu şekli - Animasyon için özel tasarım
struct LoadingBubbleShape: Shape {
    var isFromCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, 
                                cornerRadius: 15)
        
        let cornerPoint = isFromCurrentUser 
            ? CGPoint(x: rect.maxX, y: rect.minY) 
            : CGPoint(x: rect.minX, y: rect.minY)
        
        let trianglePath = UIBezierPath()
        trianglePath.move(to: cornerPoint)
        
        if isFromCurrentUser {
            trianglePath.addLine(to: CGPoint(x: rect.maxX + 8, y: rect.minY - 5))
            trianglePath.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.minY + 8))
        } else {
            trianglePath.addLine(to: CGPoint(x: rect.minX - 8, y: rect.minY - 5))
            trianglePath.addLine(to: CGPoint(x: rect.minX + 5, y: rect.minY + 8))
        }
        
        trianglePath.close()
        path.append(trianglePath)
        
        return Path(path.cgPath)
    }
} 
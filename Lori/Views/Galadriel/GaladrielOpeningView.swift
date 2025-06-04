import SwiftUI

struct GaladrielOpeningView: View {
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var circleScale: CGFloat = 0
    @State private var particleOpacity: Double = 0
    @State private var glowEffect: Double = 0
    @State private var showMainView = false
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var backgroundOpacity: Double = 0
    @State private var centerSymbolScale: CGFloat = 0
    @State private var loadingDotsOpacity: Double = 0
    
    private let gradientColors = [
        Color.white,
        Color.purple.opacity(0.8),
        Color.blue.opacity(0.6),
        Color.cyan.opacity(0.4),
        Color.pink.opacity(0.5)
    ]
    
    var body: some View {
        ZStack {
            if showMainView {
                GaladrielView()
                    .transition(.opacity)
            } else {
                // Animated gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.purple.opacity(0.1),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all, edges: .top)
                .opacity(backgroundOpacity)
                
                // Enhanced animated particles background
                ForEach(0..<25, id: \.self) { index in
                    Circle()
                        .fill(gradientColors.randomElement() ?? Color.white)
                        .frame(width: CGFloat.random(in: 1...8))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .opacity(particleOpacity * Double.random(in: 0.3...1.0))
                        .scaleEffect(CGFloat.random(in: 0.5...1.5))
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 3...6))
                                .repeatForever(autoreverses: true)
                                .delay(Double.random(in: 0...3)),
                            value: particleOpacity
                        )
                }
                
                // Floating orbs for more depth
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    gradientColors.randomElement() ?? Color.white,
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 1,
                                endRadius: 20
                            )
                        )
                        .frame(width: CGFloat.random(in: 20...50))
                        .position(
                            x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                            y: CGFloat.random(in: 100...UIScreen.main.bounds.height - 100)
                        )
                        .opacity(particleOpacity * 0.6)
                        .blur(radius: 2)
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 4...8))
                                .repeatForever(autoreverses: true)
                                .delay(Double.random(in: 1...4)),
                            value: particleOpacity
                        )
                }
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Enhanced main logo/symbol
                    ZStack {
                        // Multiple glow rings for depth
                        ForEach(0..<3, id: \.self) { ring in
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: gradientColors),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: CGFloat(4 - ring)
                                )
                                .frame(width: CGFloat(120 + ring * 20), height: CGFloat(120 + ring * 20))
                                .scaleEffect(circleScale)
                                .opacity(glowEffect * (1.0 - Double(ring) * 0.3))
                                .shadow(color: .white.opacity(0.4), radius: CGFloat(20 + ring * 10))
                                .blur(radius: CGFloat(ring))
                        }
                        
                        // Enhanced inner circle with rotation
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.9),
                                        Color.purple.opacity(0.7),
                                        Color.blue.opacity(0.5),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 80, height: 80)
                            .scaleEffect(pulseScale)
                            .rotationEffect(.degrees(rotationAngle))
                            .opacity(titleOpacity)
                            .shadow(color: .white.opacity(0.6), radius: 15)
                        
                        // Center symbol with enhanced animation
                        Image(systemName: "sparkles")
                            .font(.system(size: 30, weight: .light))
                            .foregroundColor(.white)
                            .opacity(titleOpacity)
                            .scaleEffect(centerSymbolScale)
                            .shadow(color: .white.opacity(0.8), radius: 10)
                    }
                    
                    // Enhanced title with gradient
                    Text("Galadriel")
                        .font(.system(size: 42, weight: .thin, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.white, .purple.opacity(0.8), .cyan.opacity(0.6)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(titleOpacity)
                        .shadow(color: .white.opacity(0.5), radius: 10)
                        .scaleEffect(titleOpacity * 0.2 + 0.8)
                    
                    Spacer()
                    
                    // Enhanced loading indicator
                    HStack(spacing: 12) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white, .purple.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 10, height: 10)
                                .scaleEffect(pulseScale)
                                .shadow(color: .white.opacity(0.5), radius: 5)
                                .animation(
                                    Animation.easeInOut(duration: 0.8)
                                        .repeatForever()
                                        .delay(Double(index) * 0.3),
                                    value: pulseScale
                                )
                        }
                    }
                    .opacity(loadingDotsOpacity)
                    .padding(.bottom, 120) // More space for tab bar
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Background fade in
        withAnimation(.easeIn(duration: 0.8)) {
            backgroundOpacity = 1.0
        }
        
        // Start particles with stagger
        withAnimation(.easeIn(duration: 1.5).delay(0.2)) {
            particleOpacity = 0.4
        }
        
        // Circle scale animation with spring
        withAnimation(.spring(response: 1.5, dampingFraction: 0.7).delay(0.5)) {
            circleScale = 1.0
        }
        
        // Title animation with scale
        withAnimation(.easeOut(duration: 1.8).delay(0.8)) {
            titleOpacity = 1.0
        }
        
        // Center symbol with bounce
        withAnimation(.spring(response: 1.0, dampingFraction: 0.6).delay(1.0)) {
            centerSymbolScale = 1.0
        }
        
        // Glow effect
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(1.2)) {
            glowEffect = 1.0
        }
        
        // Loading dots
        withAnimation(.easeIn(duration: 0.8).delay(2.0)) {
            loadingDotsOpacity = 1.0
        }
        
        // Continuous rotation
        withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false).delay(1.5)) {
            rotationAngle = 360
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(2.0)) {
            pulseScale = 1.15
        }
        
        // Navigate to main view after animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showMainView = true
            }
        }
    }
}

struct GaladrielOpeningView_Previews: PreviewProvider {
    static var previews: some View {
        GaladrielOpeningView()
    }
} 
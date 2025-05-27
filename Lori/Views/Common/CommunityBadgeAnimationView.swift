import SwiftUI

struct CommunityBadgeAnimationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var badgeScale: CGFloat = 0.1
    @State private var badgeOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var badgeYOffset: CGFloat = 0
    @State private var starPositions: [(x: CGFloat, y: CGFloat, rotation: Double, scale: CGFloat, opacity: Double)] = []
    @State private var glowOpacity: Double = 0
    @State private var badgePulse: CGFloat = 1.0
    @State private var burstScale: CGFloat = 0.1
    @State private var burstOpacity: Double = 0
    @State private var scatterStars: [(x: CGFloat, y: CGFloat, rotation: Double, scale: CGFloat, opacity: Double, delay: Double)] = []
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Scattered stars across entire screen
            ForEach(0..<min(scatterStars.count, 20), id: \.self) { index in
                let star = scatterStars[index]
                Image(systemName: "sparkle")
                    .foregroundColor(.white)
                    .font(.system(size: 12))
                    .rotationEffect(.degrees(star.rotation))
                    .scaleEffect(star.scale)
                    .opacity(star.opacity)
                    .position(x: star.x, y: star.y)
            }
            
            // Back button
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
            .zIndex(2)
            
            // Main content
            VStack(spacing: 30) {
                // Badge animation container
                ZStack {
                    // Central glow
                    Circle()
                        .fill(.white)
                        .frame(width: 150, height: 150)
                        .blur(radius: 30)
                        .opacity(glowOpacity)
                    
                    // Background stars
                    ForEach(0..<min(starPositions.count, 15), id: \.self) { index in
                        let star = starPositions[index]
                        Image(systemName: "sparkle")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                            .rotationEffect(.degrees(star.rotation))
                            .scaleEffect(star.scale)
                            .opacity(star.opacity)
                            .position(
                                x: UIScreen.main.bounds.width/2 + star.x,
                                y: 150 + star.y
                            )
                    }
                    
                    // Final burst effect
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [.white, .white.opacity(0.8), .white.opacity(0.3), .clear]),
                                center: .center,
                                startRadius: 5,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(burstScale)
                        .opacity(burstOpacity)
                    
                    // Radial light rays
                    ForEach(0..<12) { i in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .white.opacity(0)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 2, height: 80)
                            .offset(y: -40)
                            .rotationEffect(.degrees(Double(i) * 30.0))
                            .opacity(burstOpacity)
                            .scaleEffect(burstScale)
                    }
                    
                    // Additional sparkle effects
                    ForEach(0..<6) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .offset(
                                x: cos(Double(i) * .pi / 3) * 60,
                                y: sin(Double(i) * .pi / 3) * 60
                            )
                            .opacity(burstOpacity)
                            .scaleEffect(burstScale * 1.2)
                    }
                    
                    // Badge
                    Image("badge")
                        .resizable()
                        .interpolation(.medium)
                        .antialiased(true)
                        .frame(width: 100, height: 100)
                        .scaleEffect(badgeScale * badgePulse)
                        .opacity(badgeOpacity)
                        .offset(y: badgeYOffset)
                        .shadow(color: .white.opacity(0.5), radius: 10)
                }
                .frame(height: 300)
                
                // Text descriptions
                VStack(spacing: 20) {
                    Text("Community Badge")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.8), radius: textOpacity * 3)
                    
                    Text("This badge is given to users who make a positive contribution to the Lori community by receiving positive interactions on their posts.")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .opacity(textOpacity)
                .padding(.top, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            animateSequence()
        }
    }
    
    private func animateSequence() {
        // Initialize scattered stars across the screen
        createScatteredStars()
        
        // Start with initial glow
        withAnimation(.easeInOut(duration: 1.0)) {
            glowOpacity = 0.6
        }
        
        // Slightly delay then show the burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Show flash burst
            withAnimation(.easeInOut(duration: 0.7)) {
                burstScale = 1.5
                burstOpacity = 1.0
                glowOpacity = 0.8
            }
            
            // Show badge with burst
            withAnimation(.easeInOut(duration: 0.9)) {
                badgeOpacity = 1
                badgeScale = 0.3
            }
            
            // Fade out burst
            withAnimation(.easeInOut(duration: 1.2)) {
                burstOpacity = 0
            }
            
            // Badge rises with stars - no rotation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                createStars()
                
                withAnimation(.easeInOut(duration: 1.2)) {
                    badgeYOffset = -30
                    badgeScale = 0.8
                    glowOpacity = 0
                }
                
                // Badge pulse effect
                withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    badgePulse = 1.02
                }
                
                // Show text
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        textOpacity = 1
                    }
                }
            }
        }
    }
    
    private func createScatteredStars() {
        // Create stars scattered across the entire screen
        var newStars: [(x: CGFloat, y: CGFloat, rotation: Double, scale: CGFloat, opacity: Double, delay: Double)] = []
        
        // Get screen bounds
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Create stars
        for _ in 0..<20 {
            let randomX = CGFloat.random(in: 0...screenWidth)
            let randomY = CGFloat.random(in: 0...screenHeight)
            let randomRotation = Double.random(in: 0...360)
            let randomScale = CGFloat.random(in: 0.3...1.0)
            let randomDelay = Double.random(in: 0...2.5)
            
            newStars.append((
                x: randomX,
                y: randomY,
                rotation: randomRotation,
                scale: randomScale,
                opacity: CGFloat.random(in: 0.2...0.7),
                delay: randomDelay
            ))
        }
        
        scatterStars = newStars
        
        // Animate stars
        for i in 0..<scatterStars.count {
            let duration = 1.5 + Double.random(in: 0...0.7)
            withAnimation(
                Animation.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(scatterStars[i].delay)
            ) {
                scatterStars[i].scale = scatterStars[i].scale * CGFloat.random(in: 1.1...1.3)
                scatterStars[i].opacity = scatterStars[i].opacity * CGFloat.random(in: 0.7...0.9)
            }
        }
    }
    
    private func createStars() {
        // Create stars that appear around the badge
        var newStars: [(x: CGFloat, y: CGFloat, rotation: Double, scale: CGFloat, opacity: Double)] = []
        
        // Create stars with wide dispersion across the screen
        for _ in 0..<15 {
            let randomX = CGFloat.random(in: -UIScreen.main.bounds.width/2...UIScreen.main.bounds.width/2)
            let randomY = CGFloat.random(in: -UIScreen.main.bounds.height/2...UIScreen.main.bounds.height/2)
            let randomRotation = Double.random(in: 0...360)
            let randomScale = CGFloat.random(in: 0.5...1.5)
            
            newStars.append((x: randomX, y: randomY, rotation: randomRotation, scale: randomScale, opacity: 0))
        }
        
        starPositions = newStars
        
        // Animate stars appearing
        for i in 0..<starPositions.count {
            let appearDelay = Double(i) * 0.15 + Double.random(in: 0...0.1)
            DispatchQueue.main.asyncAfter(deadline: .now() + appearDelay) {
                withAnimation(.easeInOut(duration: 0.7)) {
                    starPositions[i].opacity = 1.0
                }
                
                // Twinkling effect
                let pulseDuration = 1.8 + Double.random(in: 0...0.5)
                withAnimation(Animation.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
                    starPositions[i].scale = starPositions[i].scale * CGFloat.random(in: 1.05...1.15)
                }
                
                // Dispersion animation - stars float outward from badge
                withAnimation(.easeInOut(duration: 2.4)) {
                    let disperseFactor = CGFloat.random(in: 1.1...1.3)
                    starPositions[i].x = starPositions[i].x * disperseFactor
                    starPositions[i].y = starPositions[i].y * disperseFactor
                }
            }
        }
    }
}

#Preview {
    CommunityBadgeAnimationView()
} 
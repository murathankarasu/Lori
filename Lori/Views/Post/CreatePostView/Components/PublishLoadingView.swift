import SwiftUI

struct PublishLoadingView: View {
    enum PublishStatus {
        case loading
        case success
        case failure
    }
    
    @Binding var status: PublishStatus
    @Binding var isPresented: Bool
    var errorMessage: String
    
    @State private var loadingProgress: Double = 0.0
    @State private var loadingRotation: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var showPulse = false
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var resultIconScale: CGFloat = 0.0
    @State private var resultTextOpacity: Double = 0.0
    @State private var loadingOpacity: Double = 1.0
    @State private var resultOpacity: Double = 0.0
    
    // For animation timing
    @State private var showResult = false
    
    var body: some View {
        ZStack {
            // Background - completely opaque and full screen
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    if status != .loading {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    // Loading animation
                    loadingAnimation
                        .padding(.bottom, 30)
                        .padding(.top, 50)
                        .opacity(loadingOpacity)
                    
                    // Result animation
                    resultAnimation
                        .padding(.bottom, 30)
                        .opacity(resultOpacity)
                }
                
                // Text area
                ZStack {
                    if status == .loading {
                        Text("Publishing your post...")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 15)
                            .opacity(textOpacity * loadingOpacity)
                            .onAppear {
                                withAnimation(.easeIn(duration: 0.4).delay(0.4)) {
                                    textOpacity = 1
                                }
                            }
                    } else if status == .success {
                        Text("Successfully posted!")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 15)
                            .opacity(resultTextOpacity)
                    } else {
                        VStack(spacing: 10) {
                            Text("Post not published")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(errorMessage)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .opacity(resultTextOpacity)
                    }
                }
                
                // Loading bar - only in loading state
                if status == .loading {
                    loadingProgressView
                        .padding(.top, 20)
                        .padding(.horizontal, 40)
                        .opacity(textOpacity * loadingOpacity)
                }
                
                Spacer()
                
                // Close button - only in success or failure state
                if status != .loading {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Text(status == .success ? "Continue" : "Try Again")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 50)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color.white)
                            )
                    }
                    .opacity(resultTextOpacity)
                    .padding(.bottom, 30)
                }
            }
            .padding()
        }
        .onAppear {
            // Start progress bar animation when loading begins
            if status == .loading {
                startLoadingAnimation()
            }
        }
        .onChange(of: status) { newStatus in
            // Show necessary animations when status changes
            if newStatus != .loading {
                // First ensure progress bar reaches 100%
                withAnimation(.easeInOut(duration: 0.5)) {
                    loadingProgress = 1.0
                }
                
                // Gradually make loading content invisible for smooth transition
                withAnimation(.easeInOut(duration: 0.6)) {
                    loadingOpacity = 0
                }
                
                // Then show result animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        showResult = true
                        resultIconScale = 1.0
                        resultOpacity = 1.0
                        resultTextOpacity = 1.0
                    }
                }
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(status == .loading)
    }
    
    // MARK: - Views
    
    // Loading animation
    private var loadingAnimation: some View {
        ZStack {
            // Outer pulse effect
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .frame(width: 120 + CGFloat(index * 30), height: 120 + CGFloat(index * 30))
                    .scaleEffect(showPulse ? 1.1 : 0.9)
                    .opacity(showPulse ? 0.3 : 0.7)
                    .animation(
                        Animation.easeInOut(duration: 1.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.4),
                        value: showPulse
                    )
            }
            
            // Middle ring - rotation animation
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white, Color.white.opacity(0.3)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 90, height: 90)
                .rotationEffect(Angle(degrees: loadingRotation))
                .onAppear {
                    withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                        loadingRotation = 360
                    }
                }
            
            // Inner circle
            Circle()
                .fill(Color.black)
                .frame(width: 75, height: 75)
                .shadow(color: Color.white.opacity(0.2), radius: 10, x: 0, y: 0)
            
            // Content icon
            Image(systemName: "doc.text")
                .font(.system(size: 30))
                .foregroundColor(.white)
                .scaleEffect(pulseScale)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulseScale = 1.1
                    }
                }
        }
        .scaleEffect(iconScale)
        .opacity(iconOpacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                iconScale = 1.0
                iconOpacity = 1
                showPulse = true
            }
        }
    }
    
    // Result animation
    private var resultAnimation: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(status == .success ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .frame(width: 130, height: 130)
            
            // Foreground circle
            Circle()
                .fill(status == .success ? Color.green : Color.red)
                .frame(width: 100, height: 100)
                .shadow(color: status == .success ? Color.green.opacity(0.5) : Color.red.opacity(0.5),
                        radius: 10, x: 0, y: 0)
            
            // Icon
            Image(systemName: status == .success ? "checkmark" : "exclamationmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(resultIconScale)
    }
    
    // Loading progress view
    private var loadingProgressView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)
                
                // Progress bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .frame(width: geometry.size.width * loadingProgress, height: 8)
            }
        }
        .frame(height: 8)
    }
    
    // Start loading animation
    private func startLoadingAnimation() {
        withAnimation(.easeInOut(duration: 2.0)) {
            loadingProgress = 0.8
        }
    }
}

#Preview {
    PublishLoadingView(
        status: .constant(.loading),
        isPresented: .constant(true),
        errorMessage: "Your message contains inappropriate content that violates our community guidelines."
    )
}

#Preview {
    PublishLoadingView(
        status: .constant(.success),
        isPresented: .constant(true),
        errorMessage: ""
    )
}

#Preview {
    PublishLoadingView(
        status: .constant(.failure),
        isPresented: .constant(true),
        errorMessage: "Your message contains inappropriate content that violates our community guidelines."
    )
} 
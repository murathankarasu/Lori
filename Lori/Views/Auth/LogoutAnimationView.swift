import SwiftUI
import FirebaseAuth

struct LogoutAnimationView: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0
    @State private var progress: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @Binding var isLoggedIn: Bool
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Logo animation
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                
                // Text animation
                VStack(spacing: 8) {
                    Text("Signing Out")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .opacity(opacity)
                    
                    Text("Signing out securely...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .opacity(opacity)
                }
            }
        }
        .onAppear {
            // Start animations
            withAnimation(.easeInOut(duration: 0.5)) {
                scale = 0.8
            }
            
            withAnimation(.easeInOut(duration: 1.0).delay(0.2)) {
                rotation = 360
            }
            
            withAnimation(.easeInOut(duration: 1.5)) {
                progress = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.5).delay(1.0)) {
                opacity = 0.8
            }
            
            // Perform logout and redirect to login
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                do {
                    try Auth.auth().signOut()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoggedIn = false
                        dismiss()
                    }
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    LogoutAnimationView(isLoggedIn: .constant(true))
} 
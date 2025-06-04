import SwiftUI

struct AboutAppInfoView: View {
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Text("L")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: isAnimating)
            
            VStack(spacing: 8) {
                Text("Lorien")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Version 1.0.0")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Redefining your social media experience")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
} 
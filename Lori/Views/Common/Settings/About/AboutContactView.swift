import SwiftUI

struct AboutContactView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                
                Text("Contact")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 25)
            
            VStack(spacing: 16) {
                ModernContactRow(
                    title: "Email",
                    value: "info@lorien.app",
                    icon: "envelope.fill",
                    iconColor: .red
                )
                
                ModernContactRow(
                    title: "Support",
                    value: "support@lorien.app",
                    icon: "headphones.circle.fill",
                    iconColor: .indigo
                )
                
                ModernContactRow(
                    title: "Social Media",
                    value: "@lorienapp",
                    icon: "at.circle.fill",
                    iconColor: .pink
                )
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }
} 
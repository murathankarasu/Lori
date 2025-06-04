import SwiftUI

struct AboutAppDetailsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                
                Text("App Details")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 25)
            
            VStack(spacing: 0) {
                ModernDetailRow(
                    title: "Developer",
                    value: "Lorien Team",
                    icon: "person.2.fill",
                    iconColor: .blue,
                    isFirst: true
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                ModernDetailRow(
                    title: "Copyright",
                    value: "© 2024 Lorien",
                    icon: "c.circle.fill",
                    iconColor: .green
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                ModernDetailRow(
                    title: "License",
                    value: "All rights reserved",
                    icon: "checkmark.shield.fill",
                    iconColor: .orange,
                    isLast: true
                )
            }
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
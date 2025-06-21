import SwiftUI

struct AboutLinksView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                
                Text("Important Links")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 25)
            
            VStack(spacing: 0) {
                Button(action: {}) {
                    ModernSettingsRow(
                        title: "Privacy Policy",
                        subtitle: "Learn how we protect your data",
                        icon: "lock.fill",
                        iconColor: .purple,
                        isFirst: true
                    )
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                Button(action: {}) {
                    ModernSettingsRow(
                        title: "Terms of Use",
                        subtitle: "Review our service terms",
                        icon: "doc.text.fill",
                        iconColor: .cyan
                    )
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                Button(action: {}) {
                    ModernSettingsRow(
                        title: "Open Source Licenses",
                        subtitle: "Libraries we use",
                        icon: "chevron.left.forwardslash.chevron.right",
                        iconColor: .mint,
                        isLast: true
                    )
                }
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
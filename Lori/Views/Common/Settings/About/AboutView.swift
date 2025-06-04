import SwiftUI

struct AboutView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                AboutHeaderView()
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        AboutAppInfoView(isAnimating: isAnimating)
                        AboutAppDetailsView()
                        AboutLinksView()
                        AboutContactView()
                        AboutFooterView()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
} 
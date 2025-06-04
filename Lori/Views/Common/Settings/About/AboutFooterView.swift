import SwiftUI

struct AboutFooterView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Made with ❤️")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
            
            Text("in Turkey")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
} 
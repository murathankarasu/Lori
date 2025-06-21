import SwiftUI
import PhotosUI

struct ToolbarView: View {
    @Binding var showMediaSelectionView: Bool
    
    var body: some View {
        HStack(spacing: 25) {
            Spacer()
            
            Button(action: {
                showMediaSelectionView = true
            }) {
                Image(systemName: "photo")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    ToolbarView(
        showMediaSelectionView: .constant(false)
    )
    .padding()
    .background(Color.black)
} 
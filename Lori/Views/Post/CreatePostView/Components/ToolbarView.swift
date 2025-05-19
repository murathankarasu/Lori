import SwiftUI
import PhotosUI

struct ToolbarView: View {
    @Binding var showEmojiPicker: Bool
    @Binding var showUserMentionPicker: Bool
    @Binding var showMediaSelectionView: Bool
    @Binding var selectedVideos: [PhotosPickerItem]
    
    var body: some View {
        HStack(spacing: 25) {
            Button(action: { showEmojiPicker = true }) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }
            
            Button(action: { showUserMentionPicker = true }) {
                Image(systemName: "at")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
            }
            
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
            
            PhotosPicker(selection: $selectedVideos, matching: .videos) {
                Image(systemName: "video")
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
        showEmojiPicker: .constant(false),
        showUserMentionPicker: .constant(false),
        showMediaSelectionView: .constant(false),
        selectedVideos: .constant([])
    )
    .padding()
    .background(Color.black)
} 
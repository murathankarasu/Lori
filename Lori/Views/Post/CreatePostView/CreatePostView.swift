import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import AVKit
import Kingfisher

// MARK: - CreatePostView
struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreatePostViewModel()
    @StateObject private var contentValidator = ContentValidationViewModel()
    @StateObject private var mediaManager = MediaManagerViewModel()
    
    @State private var showHateSpeechAlert = false
    @State private var showEmojiPicker = false
    @State private var showUserMentionPicker = false
    @State private var showMediaSelectionView = false
    @State private var selectedMediaImage: UIImage?
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    PublishButton(
                        viewModel: viewModel,
                        contentValidator: contentValidator,
                        mediaManager: mediaManager,
                        showHateSpeechAlert: $showHateSpeechAlert
                    )
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // İçerik Düzenleyici
                        ContentEditorView(
                            content: $viewModel.postContent, 
                            contentValidator: contentValidator,
                            errorMessage: viewModel.errorMessage
                        )
                        
                        // Toolbar
                        ToolbarView(
                            showEmojiPicker: $showEmojiPicker,
                            showUserMentionPicker: $showUserMentionPicker,
                            showMediaSelectionView: $showMediaSelectionView,
                            selectedVideos: $mediaManager.selectedVideos
                        )
                        
                        // Medya Önizleme
                        if selectedMediaImage != nil {
                            VStack {
                                if let image = selectedMediaImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 300)
                                        .cornerRadius(16)
                                        .padding()
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView(selectedEmoji: $contentValidator.selectedEmoji)
        }
        .sheet(isPresented: $showUserMentionPicker) {
            UserMentionPickerView(selectedUser: $contentValidator.selectedUser)
        }
        .sheet(isPresented: $showMediaSelectionView) {
            MediaSelectionView(
                selectedImage: $selectedMediaImage, 
                onImageSelected: { image in
                    if let imageData = image.jpegData(compressionQuality: 0.7),
                       let uiImage = UIImage(data: imageData) {
                        mediaManager.processedImages.append(uiImage)
                    }
                },
                onImageUploaded: { [viewModel] imageUrl, imagePath in
                    mediaManager.tempImageUrls.append(imageUrl)
                    mediaManager.tempImagePaths.append(imagePath)
                    
                    // MediaManagerViewModel için URL ve path ataması
                    if mediaManager.selectedImageURL == nil, 
                       let url = URL(string: imageUrl) {
                        mediaManager.selectedImageURL = url
                        mediaManager.selectedImagePath = imagePath
                    }
                    
                    // CreatePostViewModel için de direkt URL ve path ataması
                    viewModel.selectedImageUrl = imageUrl
                    viewModel.selectedImagePath = imagePath
                }
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 1.05).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: showMediaSelectionView)
        }
        .alert("Uyarı", isPresented: $showHateSpeechAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
                .foregroundColor(.red)
        }
        .onChange(of: mediaManager.selectedImages) { _ in
            // Birden fazla resim desteğini kaldırdık
            // Boş bırakılarak birden fazla resim işleme davranışı devre dışı bırakıldı
        }
        .onChange(of: mediaManager.selectedVideos) { _ in
            // Video desteğini kaldırdık
            // Boş bırakılarak video işleme davranışı devre dışı bırakıldı
        }
        .onDisappear {
            // Görünüm kapandığında (Back tuşu vb. ile) geçici dosyaları temizle
            if mediaManager.tempImagePaths.isEmpty && mediaManager.processedImages.isEmpty {
                Task {
                    await mediaManager.cleanupTempImages()
                }
            }
        }
    }
}

#Preview {
    CreatePostView()
}

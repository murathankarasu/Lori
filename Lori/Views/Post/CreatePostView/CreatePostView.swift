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
        NavigationStack {
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
                                .background(Color(hex: "#333333"))
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
                            // Content Editor
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
                            
                            // Media Preview
                            if selectedMediaImage != nil {
                                VStack {
                                    if let image = selectedMediaImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 300)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                            .padding()
                                    }
                                }
                                .padding(.vertical, 8)
                                .background(Color(hex: "#222222"))
                                .cornerRadius(16)
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
            .sheet(isPresented: $showMediaSelectionView, onDismiss: {
                dismissKeyboard() // Kapanırken klavyeyi kapat
            }) {
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
            .alert("Warning", isPresented: $showHateSpeechAlert) {
                Button("OK", role: .cancel) {}
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
            // Klavyeyi kapatma özelliğini aktif et
            .onTapGesture {
                dismissKeyboard()
            }
        }
    }
}

#Preview {
    CreatePostView()
}

// Klavyeyi kapatmak için yardımcı extension
extension View {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

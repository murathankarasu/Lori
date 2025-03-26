import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI

// MARK: - CreatePostView
struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreatePostViewModel()
    
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var postContent = ""
    @State private var isPublishing = false
    @State private var showHateSpeechAlert = false
    @State private var showEmojiPicker = false
    @State private var showUserMentionPicker = false
    @State private var selectedEmoji: String?
    @State private var selectedUser: String?
    
    private let maxContentLength: Double = 500
    
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
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            isPublishing = true
                            do {
                                try await viewModel.createPost()
                                dismiss()
                            } catch {
                                if let hateSpeechError = error as NSError?,
                                   hateSpeechError.domain == "HateSpeechError" {
                                    showHateSpeechAlert = true
                                } else {
                                    print("Gönderi paylaşma hatası: \(error)")
                                }
                            }
                            isPublishing = false
                        }
                    }) {
                        Text("Paylaş")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 40)
                            .background(postContent.isEmpty ? Color.gray : Color.blue)
                            .clipShape(Capsule())
                    }
                    .disabled(postContent.isEmpty || isPublishing)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Content Editor
                        TextEditor(text: $postContent)
                            .frame(height: 150)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .onChange(of: postContent) { newValue in
                                Task {
                                    if !newValue.isEmpty {
                                        do {
                                            let result = try await viewModel.checkHateSpeech(text: newValue)
                                            if result.data.isHateSpeech {
                                                showHateSpeechAlert = true
                                            }
                                        } catch {
                                            print("Nefret söylemi kontrolü hatası: \(error)")
                                        }
                                    }
                                }
                            }
                        
                        // Toolbar
                        HStack(spacing: 20) {
                            Button(action: { showEmojiPicker = true }) {
                                Image(systemName: "face.smiling")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: { showUserMentionPicker = true }) {
                                Image(systemName: "at")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Button(action: { isImagePickerPresented = true }) {
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Image Preview
                        if let image = selectedImage {
                            VStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(12)
                                
                                Button(action: { selectedImage = nil }) {
                                    Text("Fotoğrafı Kaldır")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                }
                                .padding(.top, 8)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView(selectedEmoji: $selectedEmoji)
        }
        .sheet(isPresented: $showUserMentionPicker) {
            UserMentionPickerView(selectedUser: $selectedUser)
        }
        .alert("Nefret Söylemi Uyarısı", isPresented: $showHateSpeechAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

#Preview {
    CreatePostView()
}

// MARK: - TopBarView

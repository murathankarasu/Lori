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
                        print("\n=== Kontrol Butonu Tıklandı ===")
                        print("İçerik: \(viewModel.postContent)")
                        Task {
                            isPublishing = true
                            do {
                                print("Nefret söylemi kontrolü başlıyor...")
                                let (isHateSpeech, category, _) = try await viewModel.checkHateSpeech()
                                print("Kontrol sonucu:")
                                print("- Nefret söylemi var mı?: \(isHateSpeech)")
                                print("- Kategori: \(category)")
                                
                                if isHateSpeech {
                                    viewModel.errorMessage = "Politikalarımız gereği mesajınıza izin verilmiyor. Kategori: \(category)"
                                    print("❌ Nefret söylemi tespit edildi")
                                } else {
                                    viewModel.errorMessage = ""
                                    print("✅ Nefret söylemi tespit edilmedi")
                                    // Nefret söylemi yoksa gönderiyi paylaş
                                    print("Gönderi paylaşılıyor...")
                                    try await viewModel.createPost()
                                    print("✅ Gönderi başarıyla paylaşıldı")
                                    dismiss()
                                }
                            } catch {
                                print("❌ İşlem hatası: \(error)")
                            }
                            isPublishing = false
                            print("===================\n")
                        }
                    }) {
                        HStack {
                            if viewModel.errorMessage.isEmpty {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                            } else {
                                Text("Paylaş")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(width: 80, height: 40)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(viewModel.postContent.isEmpty || isPublishing)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Content Editor
                        TextEditor(text: $viewModel.postContent)
                            .frame(height: 150)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .onChange(of: viewModel.postContent) { newValue in
                                // Sadece nokta veya ünlem işareti ile biten cümlelerde kontrol yap
                                if newValue.hasSuffix(".") || newValue.hasSuffix("!") {
                                    Task {
                                        if !newValue.isEmpty {
                                            do {
                                                let (isHateSpeech, category, _) = try await viewModel.checkHateSpeech()
                                                if isHateSpeech {
                                                    viewModel.errorMessage = "Politikalarımız gereği mesajınıza izin verilmiyor. Kategori: \(category)"
                                                } else {
                                                    viewModel.errorMessage = ""
                                                }
                                            } catch {
                                                print("Nefret söylemi kontrolü hatası: \(error)")
                                            }
                                        }
                                    }
                                }
                            }
                        
                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                                .font(.body)
                                .padding(.horizontal)
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
        .alert("Uyarı", isPresented: $showHateSpeechAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
                .foregroundColor(.red)
        }
    }
}

#Preview {
    CreatePostView()
}

// MARK: - TopBarView

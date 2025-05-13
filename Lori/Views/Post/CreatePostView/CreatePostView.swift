import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import AVKit

// MARK: - CreatePostView
struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreatePostViewModel()
    
    @State private var isImagePickerPresented = false
    @State private var isPublishing = false
    @State private var showHateSpeechAlert = false
    @State private var showEmojiPicker = false
    @State private var showUserMentionPicker = false
    @State private var selectedEmoji: String?
    @State private var selectedUser: String?
    @State private var showVideoPicker = false
    
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
                                // Nefret söylemi kontrolü
                                let (isHateSpeech, category, _) = try await viewModel.checkHateSpeech()
                                if isHateSpeech {
                                    viewModel.errorMessage = "Politikalarımız gereği mesajınıza izin verilmiyor. Kategori: \(category)"
                                } else {
                                    viewModel.errorMessage = ""
                                }
                                // Medya dosyalarını işle ve analiz et
                                print("Medya dosyaları işleniyor...")
                                await viewModel.processMedia()
                                // Her durumda paylaşımı yap (nefret söylemi koleksiyonuna veya normal koleksiyona kaydedilecek)
                                try await viewModel.createPost()
                                // Sadece başarılıysa ekranı kapat
                                dismiss()
                            } catch {
                                viewModel.errorMessage = error.localizedDescription
                            }
                            isPublishing = false
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
                            .onChange(of: viewModel.postContent) { oldValue, newValue in
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
                        
                        if viewModel.isCheckingDisinformation {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Dezenformasyon kontrolü yapılıyor...")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                            .padding()
                        }
                        
                        if let checkResult = viewModel.disinformationCheckResult {
                            DisinformationCheckSummaryView(response: checkResult)
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
                            
                            PhotosPicker(selection: $viewModel.selectedImages, matching: .images) {
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            // Video seçici
                            PhotosPicker(selection: $viewModel.selectedVideos, matching: .videos) {
                                Image(systemName: "video")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Image Preview
                        if !viewModel.processedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.processedImages.indices, id: \.self) { index in
                                        VStack {
                                            Image(uiImage: viewModel.processedImages[index])
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxHeight: 200)
                                                .cornerRadius(12)
                                            
                                            Button(action: {
                                                viewModel.processedImages.remove(at: index)
                                            }) {
                                                Text("Fotoğrafı Kaldır")
                                                    .font(.subheadline)
                                                    .foregroundColor(.red)
                                            }
                                            .padding(.top, 8)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        // Video Preview
                        if !viewModel.processedVideos.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.processedVideos.indices, id: \.self) { index in
                                        VStack {
                                            VideoPlayer(player: AVPlayer(url: viewModel.processedVideos[index]))
                                                .frame(height: 200)
                                                .cornerRadius(12)
                                            Button(action: {
                                                viewModel.processedVideos.remove(at: index)
                                            }) {
                                                Text("Videoyu Kaldır")
                                                    .font(.subheadline)
                                                    .foregroundColor(.red)
                                            }
                                            .padding(.top, 8)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding()
                }
            }
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
        .onChange(of: viewModel.selectedImages) { _ in
            Task {
                await viewModel.processSelectedImages()
            }
        }
        .onChange(of: viewModel.selectedVideos) { _ in
            Task {
                await viewModel.processSelectedVideos()
            }
        }
    }
}

#Preview {
    CreatePostView()
}

// MARK: - TopBarView

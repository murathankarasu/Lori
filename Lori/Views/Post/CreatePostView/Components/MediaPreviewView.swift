import SwiftUI
import AVKit
import Kingfisher

struct MediaPreviewView: View {
    @ObservedObject var mediaManager: MediaManagerViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // Geçici resim uyarısı
            if !mediaManager.tempImageUrls.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Geçici yüklenen görseller")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Yüklenen görseller Paylaş butonuna tıkladığınızda kalıcı olarak kaydedilecektir.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            // Resim önizleme
            if !mediaManager.processedImages.isEmpty || !mediaManager.tempImageUrls.isEmpty {
                ImagePreviewScrollView(mediaManager: mediaManager)
            }
            
            // Video önizleme
            if !mediaManager.processedVideos.isEmpty {
                VideoPreviewScrollView(mediaManager: mediaManager)
            }
        }
    }
}

struct ImagePreviewScrollView: View {
    @ObservedObject var mediaManager: MediaManagerViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                // Geçici önizlemeler (temp-posts'dan)
                ForEach(mediaManager.tempImageUrls.indices, id: \.self) { index in
                    VStack {
                        KFImage(URL(string: mediaManager.tempImageUrls[index]))
                            .placeholder {
                                ZStack {
                                    Color.gray.opacity(0.1)
                                        .cornerRadius(16)
                                    
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                .frame(width: 200, height: 200)
                            }
                            .fade(duration: 0.3)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(16)
                            .onTapGesture {
                                // Ana görsel olarak seç
                                let urlString = mediaManager.tempImageUrls[index]
                                if let url = URL(string: urlString) {
                                    mediaManager.selectedImageURL = url
                                    mediaManager.selectedImagePath = mediaManager.tempImagePaths[index]
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .overlay(
                                ZStack {
                                    // Eğer ana görsel olarak seçildiyse (selectedImageURL) 
                                    Group {
                                        if let selectedURL = mediaManager.selectedImageURL?.absoluteString, 
                                           selectedURL == mediaManager.tempImageUrls[index] {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.system(size: 24))
                                                .padding(8)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.system(size: 24))
                                                .padding(8)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                        }
                                    }
                                    .padding(8)
                                },
                                alignment: .topTrailing
                            )
                        
                        Button(action: {
                            // Görseli hem UI'dan hem de storage'dan kaldır
                            Task {
                                // Önce path bilgisini al
                                let path = mediaManager.tempImagePaths[index]
                                
                                // Diziyi güncelle (önce path sonra url silmek önemli)
                                let pathToRemove = mediaManager.tempImagePaths.remove(at: index)
                                mediaManager.tempImageUrls.remove(at: index)
                                
                                // Firebase'den sil
                                await mediaManager.deleteSingleTempImage(path: pathToRemove)
                            }
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                Text("Kaldır")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                }
                
                // Normal işlenmiş resimler (UIImage olarak)
                ForEach(mediaManager.processedImages.indices, id: \.self) { index in
                    VStack {
                        Image(uiImage: mediaManager.processedImages[index])
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button(action: {
                            mediaManager.processedImages.remove(at: index)
                        }) {
                            Text("Kaldır")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct VideoPreviewScrollView: View {
    @ObservedObject var mediaManager: MediaManagerViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(mediaManager.processedVideos.indices, id: \.self) { index in
                    VStack {
                        VideoPlayer(player: AVPlayer(url: mediaManager.processedVideos[index]))
                            .frame(height: 200)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button(action: {
                            mediaManager.processedVideos.remove(at: index)
                        }) {
                            Text("Kaldır")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    MediaPreviewView(mediaManager: MediaManagerViewModel())
        .padding()
        .background(Color.black)
} 
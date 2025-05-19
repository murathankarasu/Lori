import SwiftUI
import AVKit
import Kingfisher

struct MediaPreviewView: View {
    @ObservedObject var mediaManager: MediaManagerViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // Temporary image warning
            if !mediaManager.tempImageUrls.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Temporarily uploaded images")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Uploaded images will be permanently saved when you click the Publish button.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(hex: "#1A1A1A"))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
            }
            
            // Image previews
            if !mediaManager.processedImages.isEmpty || !mediaManager.tempImageUrls.isEmpty {
                ImagePreviewScrollView(mediaManager: mediaManager)
            }
            
            // Video previews
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
                // Temporary previews
                ForEach(mediaManager.tempImageUrls.indices, id: \.self) { index in
                    VStack {
                        KFImage(URL(string: mediaManager.tempImageUrls[index]))
                            .placeholder {
                                ZStack {
                                    Color(hex: "#222222")
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
                                // Select as main image
                                let urlString = mediaManager.tempImageUrls[index]
                                if let url = URL(string: urlString) {
                                    mediaManager.selectedImageURL = url
                                    mediaManager.selectedImagePath = mediaManager.tempImagePaths[index]
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .overlay(
                                ZStack {
                                    // If selected as main image
                                    Group {
                                        if let selectedURL = mediaManager.selectedImageURL?.absoluteString, 
                                           selectedURL == mediaManager.tempImageUrls[index] {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.system(size: 24))
                                                .padding(8)
                                                .background(Color.black.opacity(0.7))
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.system(size: 24))
                                                .padding(8)
                                                .background(Color.black.opacity(0.7))
                                                .clipShape(Circle())
                                        }
                                    }
                                    .padding(8)
                                },
                                alignment: .topTrailing
                            )
                        
                        Button(action: {
                            // Remove image from both UI and storage
                            Task {
                                // Get path info first
                                let path = mediaManager.tempImagePaths[index]
                                
                                // Update array (important to remove path then url)
                                let pathToRemove = mediaManager.tempImagePaths.remove(at: index)
                                mediaManager.tempImageUrls.remove(at: index)
                                
                                // Delete from Firebase
                                await mediaManager.deleteSingleTempImage(path: pathToRemove)
                            }
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                Text("Remove")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color(hex: "#333333"))
                            .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                }
                
                // Normal processed images (as UIImage)
                ForEach(mediaManager.processedImages.indices, id: \.self) { index in
                    VStack {
                        Image(uiImage: mediaManager.processedImages[index])
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        Button(action: {
                            mediaManager.processedImages.remove(at: index)
                        }) {
                            Text("Remove")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color(hex: "#333333"))
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
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        Button(action: {
                            mediaManager.processedVideos.remove(at: index)
                        }) {
                            Text("Remove")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color(hex: "#333333"))
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
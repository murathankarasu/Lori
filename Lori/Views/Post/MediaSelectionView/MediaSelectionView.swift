import SwiftUI
import PhotosUI

struct MediaSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MediaSelectionViewModel()
    
    // CreatePostView'dan bağlanan değişkenler
    @Binding var selectedImage: UIImage?
    var onImageSelected: ((UIImage) -> Void)?
    // Yeni eklenen URL ve path callback'leri
    var onImageUploaded: ((String, String) -> Void)?
    
    // UI değişkenleri
    @State private var photoItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
    @State private var isLoading = false
    @State private var showAnimation = false
    
    var body: some View {
        ZStack {
            // Arkaplan
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Başlık
                Text("Select Image")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Görsel önizleme alanı
                ZStack {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .cornerRadius(12)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    .padding()
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 300)
                            .padding()
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("No image selected")
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.top, 8)
                                }
                            )
                    }
                    
                    // Bilgi etiketi - görsel boyutları hakkında bilgi verme
                    VStack {
                        Spacer()
                        Text("Images will be displayed in 400x350 pixels.\nFor best results, upload an image with 4:3 ratio.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 24)
                    .padding(.horizontal, 30)
                    
                    // Analiz devam ederken yükleme göstergesi
                    if viewModel.isAnalyzing {
                        ZStack {
                            Color.black.opacity(0.8)
                                .cornerRadius(16)
                                .padding()
                            
                            VStack {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.5)
                                
                                Text("Analyzing image...")
                                    .foregroundColor(.white)
                                    .padding(.top, 16)
                            }
                        }
                        .transition(.scale)
                    }
                    
                    // Yükleme durumu göstergesi
                    if viewModel.isUploading {
                        ZStack {
                            Color.black.opacity(0.8)
                                .cornerRadius(16)
                                .padding()
                            
                            VStack {
                                // İlerleme çubuğu
                                ProgressView(value: viewModel.uploadProgress, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                    .frame(width: 200)
                                    .padding(.bottom, 8)
                                
                                Text("Uploading... \(Int(viewModel.uploadProgress * 100))%")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                        }
                        .transition(.scale)
                    }
                }
                
                // Hata mesajı
                if !viewModel.errorMessage.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                        
                        Text(viewModel.errorMessage)
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 15)
                    .padding(.horizontal, 25)
                    .background(Color.red.opacity(0.3))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Analiz sonucu detayları
                if let result = viewModel.analysisResult, !result.isSafe {
                    detailedAnalysisView(result: result)
                        .padding(.horizontal)
                }
                
                // Yükleme durumu başarılı ise göster
                if viewModel.imageUrl != nil && !viewModel.isUploading {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Image temporarily uploaded")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Butonlar
                VStack(spacing: 15) {
                    // Görsel seçme butonu
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Select from Gallery")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#333333"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .disabled(viewModel.isAnalyzing || viewModel.isUploading)
                    
                    // Alt butonlar (Onayla/İptal)
                    HStack(spacing: 20) {
                        // İptal butonu
                        Button(action: {
                            // Eğer bir görsel yüklendiyse silmeye çalış
                            if viewModel.imageStoragePath != nil {
                                Task {
                                    await viewModel.deleteUploadedImage()
                                }
                            }
                            
                            withAnimation {
                                dismiss()
                            }
                        }) {
                            Text("Cancel")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#444444"))
                                .cornerRadius(12)
                        }
                        
                        // Onayla butonu
                        Button(action: {
                            if let image = viewModel.selectedImage, let imageUrl = viewModel.imageUrl, let imagePath = viewModel.imageStoragePath {
                                // Onay animasyonu göster
                                withAnimation {
                                    showAnimation = true
                                }
                                
                                // Görseli CreatePostView'a aktar
                                selectedImage = image
                                onImageSelected?(image)
                                // URL'yi de aktar
                                onImageUploaded?(imageUrl, imagePath)
                                
                                print("Onayla butonuyla görsel aktarıldı: \(imageUrl)")
                                                                
                                // Kısa bir gecikme sonra kapat
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    dismiss()
                                }
                            }
                        }) {
                            Text("Confirm")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    (viewModel.isApproved && viewModel.imageUrl != nil && !viewModel.isUploading) 
                                    ? Color.green 
                                    : Color(hex: "#555555")
                                )
                                .cornerRadius(12)
                        }
                        .disabled(!viewModel.isApproved || viewModel.imageUrl == nil || viewModel.isUploading)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            
            // Onaylama animasyonu
            if showAnimation {
                ZStack {
                    Color.black.opacity(0.85)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        LottieView(name: "success_check")
                            .frame(width: 140, height: 140)
                        
                        Text("Image Confirmed!")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.top, 10)
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
            
            // Geri bildirim animasyonu
            if viewModel.showFeedbackAnimation {
                feedbackAnimationView
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showFeedbackAnimation)
                    .zIndex(2)
            }
        }
        .onChange(of: photoItem) { _, newValue in
            if let newValue = newValue {
                Task {
                    isLoading = true
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.selectedImage = uiImage
                        await viewModel.processSelectedImage()
                        
                        // Analiz sonucu olumlu ise ve yükleme tamamlandıysa onaylama işlemini yap
                        if viewModel.isApproved && viewModel.imageUrl != nil && !viewModel.isUploading {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAnimation = true
                            }
                            
                            // Görsel bilgilerini aktarım için hazırla
                            if let image = viewModel.selectedImage, 
                               let imageUrl = viewModel.imageUrl, 
                               let imagePath = viewModel.imageStoragePath {
                                // URL kullanıma hazır olana kadar bekle
                                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 saniye bekle
                                
                                // Verileri aktar
                                selectedImage = image
                                onImageSelected?(image)
                                onImageUploaded?(imageUrl, imagePath)
                                
                                print("MediaSelectionView: Görsel yükleme tamamlandı. URL: \(imageUrl)")
                                
                                // Sayfayı kapat
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            }
                        }
                    }
                    isLoading = false
                    
                    // Her yeni görsel seçiminde önceki URL'yi sıfırla (eğer otomatik kabul edilmediyse)
                    if !viewModel.isApproved && viewModel.imageStoragePath != nil {
                        await viewModel.deleteUploadedImage()
                    }
                }
            }
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.3), value: showAnimation)
        .onDisappear {
            // Görünüm kapandığında eğer görsel onaylanmadıysa ve hala bir yükleme varsa sil
            if !showAnimation && viewModel.imageStoragePath != nil {
                Task {
                    await viewModel.deleteUploadedImage()
                }
            }
        }
    }
    
    // Detaylı analiz sonuçları görünümü
    private func detailedAnalysisView(result: MediaAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Analysis Results:")
                .font(.headline)
                .foregroundColor(.white)
            
            if result.highestNegativeCategories.isEmpty {
                Text("No significant violation categories detected.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            } else {
                ForEach(result.highestNegativeCategories, id: \.0) { category, score in
                    HStack {
                        Text(category.capitalized)
                            .foregroundColor(.white)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        // Skoru görsel olarak göster
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 100, height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(scoreColor(for: score))
                                .frame(width: 100 * CGFloat(score), height: 8)
                        }
                        
                        Text("\(Int(score * 100))%")
                            .foregroundColor(scoreColor(for: score))
                            .font(.caption)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color(hex: "#222222"))
        .cornerRadius(12)
    }
    
    // Skor rengini belirle
    private func scoreColor(for score: Double) -> Color {
        if score >= 0.7 {
            return .red
        } else if score >= 0.5 {
            return .orange
        } else {
            return .yellow
        }
    }
    
    // Geri bildirim animasyonu görünümü
    private var feedbackAnimationView: some View {
        ZStack {
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Sonuç tipine göre uygun Lottie animasyonu göster
                Group {
                    switch viewModel.feedbackType {
                    case .success:
                        LottieView(name: "check_animation")
                            .frame(width: 100, height: 100)
                    case .violation:
                        LottieView(name: "warning_animation")
                            .frame(width: 100, height: 100)
                    case .error:
                        LottieView(name: "error_animation")
                            .frame(width: 100, height: 100)
                    }
                }
                
                Text(viewModel.feedbackMessage)
                    .foregroundColor(.white)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                if viewModel.feedbackType != .success {
                    Text("Try again with a different image")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#222222"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(viewModel.feedbackType.color.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: viewModel.feedbackType.color.opacity(0.3), radius: 20)
        }
    }
}

struct LottieView: View {
    var name: String
    
    var body: some View {
        // Bu bir örnek implementasyondur. Gerçek uygulamada Lottie kütüphanesi entegre edilmelidir.
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.2))
            
            Image(systemName: name == "success_check" || name == "check_animation" ? "checkmark.circle.fill" :
                  name == "warning_animation" ? "exclamationmark.triangle.fill" : "xmark.octagon.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(name == "success_check" || name == "check_animation" ? .green :
                                name == "warning_animation" ? .orange : .red)
                .padding(20)
        }
    }
}

#Preview {
    MediaSelectionView(selectedImage: .constant(nil))
} 
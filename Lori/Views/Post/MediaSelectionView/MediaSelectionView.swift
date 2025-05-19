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
                Text("Görsel Seç")
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
                            .cornerRadius(8)
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .padding()
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 300)
                            .padding()
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.7))
                                    Text("Görsel seçilmedi")
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.top, 8)
                                }
                            )
                    }
                    
                    // Bilgi etiketi - görsel boyutları hakkında bilgi verme
                    VStack {
                        Spacer()
                        Text("Görseller 400x350 piksel boyutunda gösterilir.\nEn iyi sonuç için 4:3 oranında görsel yükleyin.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                    }
                    .padding(.bottom, 24)
                    .padding(.horizontal, 30)
                    
                    // Analiz devam ederken yükleme göstergesi
                    if viewModel.isAnalyzing {
                        ZStack {
                            Color.black.opacity(0.7)
                                .cornerRadius(16)
                                .padding()
                            
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text("Görsel analiz ediliyor...")
                                    .foregroundColor(.white)
                                    .padding(.top, 16)
                            }
                        }
                        .transition(.opacity)
                    }
                    
                    // Yükleme durumu göstergesi
                    if viewModel.isUploading {
                        ZStack {
                            Color.black.opacity(0.7)
                                .cornerRadius(16)
                                .padding()
                            
                            VStack {
                                // İlerleme çubuğu
                                ProgressView(value: viewModel.uploadProgress, total: 1.0)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                    .frame(width: 200)
                                    .padding(.bottom, 8)
                                
                                Text("Yükleniyor... %\(Int(viewModel.uploadProgress * 100))")
                                    .foregroundColor(.white)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                        }
                        .transition(.opacity)
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
                    .background(Color.red.opacity(0.8))
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
                        Text("Görsel geçici olarak yüklendi")
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
                            Text("Galeriden Seç")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.8))
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
                            Text("İptal")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
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
                            Text("Onayla")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    (viewModel.isApproved && viewModel.imageUrl != nil && !viewModel.isUploading) 
                                    ? Color.green.opacity(0.8) 
                                    : Color.gray.opacity(0.3)
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
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.green)
                        
                        Text("Görsel onaylandı!")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.top, 20)
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
            Text("Analiz Sonuçları:")
                .font(.headline)
                .foregroundColor(.white)
            
            if result.highestNegativeCategories.isEmpty {
                Text("Belirgin bir ihlal kategorisi tespit edilmedi.")
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
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(scoreColor(for: score))
                                .frame(width: 100 * CGFloat(score), height: 8)
                        }
                        
                        Text("%\(Int(score * 100))")
                            .foregroundColor(scoreColor(for: score))
                            .font(.caption)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
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
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image(systemName: viewModel.feedbackType.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(viewModel.feedbackType.color)
                
                Text(viewModel.feedbackMessage)
                    .foregroundColor(.white)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                if viewModel.feedbackType != .success {
                    Text("Görsel içeriğini değiştirip tekrar deneyin")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
                    .blur(radius: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(viewModel.feedbackType.color.opacity(0.5), lineWidth: 2)
            )
            .shadow(color: viewModel.feedbackType.color.opacity(0.3), radius: 20)
        }
    }
}

#Preview {
    MediaSelectionView(selectedImage: .constant(nil))
} 
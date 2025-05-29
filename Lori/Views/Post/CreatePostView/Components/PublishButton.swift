import SwiftUI
import FirebaseAuth // Auth.auth() kullanımı için gerekli
import FirebaseFirestore // Timestamp kullanımı için

// Klavyeyi kapatma fonksiyonu
extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct PublishButton: View {
    @ObservedObject var viewModel: CreatePostViewModel
    @ObservedObject var contentValidator: ContentValidationViewModel
    @ObservedObject var mediaManager: MediaManagerViewModel
    @Binding var showHateSpeechAlert: Bool
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isPublishing = false
    @State private var showPublishingOverlay = false
    @State private var publishStatus: PublishLoadingView.PublishStatus = .loading
    
    var body: some View {
        ZStack {
            Button(action: {
                print("\n=== Publish Button Tapped ===")
                print("Content: \(viewModel.postContent)")
                
                // Yükleme ekranını göster ve klavye kapansın
                publishStatus = .loading
                UIApplication.shared.dismissKeyboard()
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPublishingOverlay = true
                }
                
                Task {
                    do {
                        // Nefret söylemi kontrolü
                        let (isHateSpeech, category, _) = try await viewModel.checkHateSpeech()
                        
                        if isHateSpeech {
                            // Nefret söylemi tespit edildi
                            viewModel.errorMessage = "Your message violates our policies. Category: \(category)"
                            
                            // Hata gösterimi için status'u güncelle
                            DispatchQueue.main.async {
                                publishStatus = .failure
                            }
                        } else {
                            // Nefret söylemi yok, işleme devam
                            viewModel.errorMessage = ""
                            
                            // Medya işleme
                            print("Starting media processing...")
                            await viewModel.processMedia()
                            
                            // Gönderiyi oluştur
                            try await viewModel.createPost()
                            
                            // Başarılı durumu göster
                            DispatchQueue.main.async {
                                publishStatus = .success
                                
                                // 2 saniye sonra ekranı kapat
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    dismiss() // CreatePostView'ı kapat
                                }
                            }
                        }
                    } catch {
                        // İşlem sırasında hata oluştu
                        viewModel.errorMessage = error.localizedDescription
                        viewModel.showError = true
                        
                        // Hata gösterimi için status'u güncelle
                        DispatchQueue.main.async {
                            publishStatus = .failure
                        }
                    }
                }
            }) {
                // Buton görünümü - beyaz zemin üzerine siyah simge
                HStack {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(width: 100, height: 40)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
            .disabled(viewModel.postContent.isEmpty || isPublishing)
        }
        // Tam ekran yükleme overlay'i - ZStack dışına taşıdım
        .fullScreenCover(isPresented: $showPublishingOverlay) {
            PublishLoadingView(
                status: $publishStatus,
                isPresented: $showPublishingOverlay,
                errorMessage: viewModel.errorMessage
            )
        }
    }
}

// Not: Önceki FollowingFeedView tanımı kaldırıldı. Orijinal FollowingFeedView zaten başka bir dosyada mevcut.

#Preview {
    PublishButton(
        viewModel: CreatePostViewModel(),
        contentValidator: ContentValidationViewModel(),
        mediaManager: MediaManagerViewModel(),
        showHateSpeechAlert: .constant(false)
    )
} 

import SwiftUI

struct PublishButton: View {
    @ObservedObject var viewModel: CreatePostViewModel
    @ObservedObject var contentValidator: ContentValidationViewModel
    @ObservedObject var mediaManager: MediaManagerViewModel
    @Binding var showHateSpeechAlert: Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var isPublishing = false
    
    var body: some View {
        Button(action: {
            print("\n=== Kontrol Butonu Tıklandı ===")
            print("İçerik: \(viewModel.postContent)")
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isPublishing = true
            }
            
            Task {
                do {
                    // Nefret söylemi kontrolü
                    let (isHateSpeech, category, _) = try await viewModel.checkHateSpeech()
                    if isHateSpeech {
                        viewModel.errorMessage = "Politikalarımız gereği mesajınıza izin verilmiyor. Kategori: \(category)"
                        withAnimation {
                            showHateSpeechAlert = true
                        }
                    } else {
                        viewModel.errorMessage = ""
                        
                        // Medya işleme - medya yoksa bu adım hızlıca atlanır
                        print("Medya işlemi başlatılıyor...")
                        await viewModel.processMedia()
                        
                        // Gönderiyi oluştur
                        try await viewModel.createPost()
                        
                        // Başarılı paylaşım animasyonu ve kapanış
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dismiss()
                        }
                    }
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.showError = true
                }
                
                withAnimation {
                    isPublishing = false
                }
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
            .foregroundColor(.white)
            .frame(width: 100, height: 40)
            .background(Color.blue.opacity(0.8))
            .clipShape(Capsule())
        }
        .disabled(viewModel.postContent.isEmpty || isPublishing)
    }
}

#Preview {
    PublishButton(
        viewModel: CreatePostViewModel(),
        contentValidator: ContentValidationViewModel(),
        mediaManager: MediaManagerViewModel(),
        showHateSpeechAlert: .constant(false)
    )
} 
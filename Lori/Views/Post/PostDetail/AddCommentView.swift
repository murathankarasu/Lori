import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddCommentView: View {
    let post: Post
    @StateObject private var viewModel = AddCommentViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Üst bar
            HStack {
                Button("İptal") { dismiss() }
                    .foregroundColor(.white)
                Spacer()
                Text("Yorum Yap")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    Task {
                        await viewModel.addComment(to: post) { success in
                            if success { dismiss() }
                        }
                    }
                }) {
                    if viewModel.isPosting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Gönder")
                            .foregroundColor(viewModel.canPost ? .white : .gray)
                    }
                }
                .disabled(!viewModel.canPost)
            }
            .padding()
            .background(Color.black)
            
            // Yorum alanı
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.commentText)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                if viewModel.commentText.isEmpty {
                    Text("Yorumunuzu yazın...")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }
            }
            .padding(.top, 8)
            
            // Karakter sayacı
            HStack {
                Spacer()
                Text("\(viewModel.commentText.count)/\(viewModel.maxContentLength)")
                    .foregroundColor(viewModel.commentText.count > viewModel.maxContentLength ? .red : .gray)
                    .font(.caption)
                    .padding(.trailing, 24)
            }
            .padding(.bottom, 8)
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .alert("Nefret Söylemi Tespit Edildi", isPresented: $viewModel.showHateSpeechWarning) {
            Button("Tamam", role: .cancel) { viewModel.showHateSpeechWarning = false }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Hata", isPresented: $viewModel.showError) {
            Button("Tamam", role: .cancel) { viewModel.showError = false }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
} 

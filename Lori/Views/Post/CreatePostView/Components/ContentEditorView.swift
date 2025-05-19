import SwiftUI

struct ContentEditorView: View {
    @Binding var content: String
    @ObservedObject var contentValidator: ContentValidationViewModel
    var errorMessage: String
    
    var body: some View {
        VStack(spacing: 10) {
            TextEditor(text: $content)
                .frame(height: 150)
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(16)
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .onChange(of: content) { oldValue, newValue in
                    if newValue.hasSuffix(".") || newValue.hasSuffix("!") {
                        Task {
                            if !newValue.isEmpty {
                                do {
                                    let (isHateSpeech, category, _) = try await contentValidator.checkHateSpeech(text: newValue)
                                    if isHateSpeech {
                                        // Uyarı burada gösterilecek
                                    }
                                } catch {
                                    print("Nefret söylemi kontrolü hatası: \(error)")
                                }
                            }
                        }
                    }
                }
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.body)
                    .padding(.horizontal)
            }
            
            if contentValidator.isCheckingDisinformation {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Dezenformasyon kontrolü yapılıyor...")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                .padding()
            }
            
            if let checkResult = contentValidator.disinformationCheckResult {
                CreatePostDisinformationCheckSummaryView(response: checkResult)
                    .padding(.horizontal)
            }
        }
    }
}

#Preview {
    ContentEditorView(
        content: .constant("Bu bir test içeriğidir."),
        contentValidator: ContentValidationViewModel(),
        errorMessage: ""
    )
    .padding()
    .background(Color.black)
} 
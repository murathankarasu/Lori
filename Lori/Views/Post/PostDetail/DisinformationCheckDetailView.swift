import SwiftUI

struct DisinformationCheckDetailView: View {
    let response: DisinformationResponse
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Başlık ve Durum
                    HStack {
                        Image(systemName: response.isVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(response.isVerified ? .green : .orange)
                        
                        VStack(alignment: .leading) {
                            Text(response.isVerified ? "Doğrulanmış İçerik" : "Doğrulanamayan İçerik")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Confidence Score: %\(Int(response.confidence * 100))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Açıklama
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Explanation")
                            .font(.headline)
                        
                        Text(response.explanation)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Kaynaklar
                    if let sources = response.sources, !sources.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sources")
                                .font(.headline)
                            
                            ForEach(sources, id: \.self) { source in
                                Link(destination: URL(string: source)!) {
                                    HStack {
                                        Image(systemName: "link")
                                            .foregroundColor(.blue)
                                        Text(source)
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                }
                .padding()
            }
            .navigationBarTitle("Dezenformasyon Kontrolü", displayMode: .inline)
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
            .background(Color(.systemGray6))
        }
    }
}

struct DisinformationCheckDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DisinformationCheckDetailView(
            response: DisinformationResponse(
                isVerified: true,
                sources: ["https://example.com/source1", "https://example.com/source2"],
                confidence: 0.95,
                explanation: "Bu içerik güvenilir kaynaklarca doğrulanmıştır."
            )
        )
    }
} 
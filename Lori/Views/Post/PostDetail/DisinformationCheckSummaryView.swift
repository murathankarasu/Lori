import SwiftUI

struct DisinformationCheckSummaryView: View {
    let response: DisinformationResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: response.isVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(response.isVerified ? .green : .orange)
                
                Text(response.isVerified ? "Bu içerik doğrulanmıştır" : "Bu içerik için doğrulama yapılamadı")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            if let sources = response.sources, !sources.isEmpty {
                Text("Kaynaklar:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                ForEach(sources, id: \.self) { source in
                    Link(destination: URL(string: source)!) {
                        Text(source)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }
            }
            
            Text(response.explanation)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct DisinformationCheckSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        DisinformationCheckSummaryView(
            response: DisinformationResponse(
                isVerified: true,
                sources: ["https://example.com/source1"],
                confidence: 0.95,
                explanation: "Bu içerik doğrulanmıştır."
            )
        )
    }
} 
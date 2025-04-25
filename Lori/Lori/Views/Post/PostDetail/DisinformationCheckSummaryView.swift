import SwiftUI

struct DisinformationCheckSummaryView: View {
    let response: DisinformationResponse
    
    private var statusColor: Color {
        if response.isVerified {
            return .green
        } else if response.confidence > 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var statusIcon: String {
        if response.isVerified {
            return "checkmark.shield.fill"
        } else if response.confidence > 0.5 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.shield.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: statusIcon)
                    .font(.system(size: 24))
                    .foregroundColor(statusColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(response.explanation.components(separatedBy: "\n\n").first ?? "")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Güven Skoru: %\(Int(response.confidence * 100))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if let sources = response.sources, !sources.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kaynaklar")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    
                    ForEach(sources, id: \.self) { source in
                        Link(destination: URL(string: source)!) {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                Text(source)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            
            Text(response.explanation.components(separatedBy: "\n\n").last ?? "")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct DisinformationCheckSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DisinformationCheckSummaryView(
                response: DisinformationResponse(
                    isVerified: true,
                    sources: ["https://example.com/source1"],
                    confidence: 0.95,
                    explanation: "✅ İçerik Doğrulandı\n\nBu bilgi Güvenilir Kaynak tarafından doğrulanmıştır. İçerik güvenilir kaynaklarca desteklenmektedir ve doğru bilgi içermektedir."
                )
            )
            .previewLayout(.sizeThatFits)
            .padding()
            
            DisinformationCheckSummaryView(
                response: DisinformationResponse(
                    isVerified: false,
                    sources: ["https://example.com/source1"],
                    confidence: 0.3,
                    explanation: "❌ Yanlış Bilgi\n\nGüvenilir Kaynak tarafından yapılan inceleme sonucunda, bu içerikte yanlış veya yanıltıcı bilgiler tespit edilmiştir. Lütfen güvenilir kaynaklardan bilgi almayı tercih edin."
                )
            )
            .previewLayout(.sizeThatFits)
            .padding()
        }
    }
} 
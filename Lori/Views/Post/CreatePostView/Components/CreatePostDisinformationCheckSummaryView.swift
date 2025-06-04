import SwiftUI

struct CreatePostDisinformationCheckSummaryView: View {
    let response: DisinformationResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: !response.isVerified ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                    .foregroundColor(!response.isVerified ? .orange : .green)
                    .font(.system(size: 20))
                
                Text(!response.isVerified ? "Disinformation Risk" : "Trusted Content")
                    .font(.headline)
                    .foregroundColor(!response.isVerified ? .orange : .green)
                
                Spacer()
                
                Text("\(Int(response.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if !response.explanation.isEmpty {
                Text(response.explanation)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.vertical, 5)
            }
            
            if !response.isVerified, let sources = response.sources, !sources.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Alternative Sources:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    ForEach(sources, id: \.self) { source in
                        HStack(spacing: 5) {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            
                            Text(source)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(!response.isVerified ? .orange : .green).opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(!response.isVerified ? .orange : .green).opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    CreatePostDisinformationCheckSummaryView(
        response: DisinformationResponse(
            isVerified: false,
            sources: ["https://www.guvenilikaynak.com/dogrulama", "https://www.teyit.org"],
            confidence: 0.85,
            explanation: "This content contains information that could not be verified by reliable sources."
        )
    )
    .padding()
    .background(Color.black)
} 
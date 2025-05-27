import SwiftUI

struct GaladrielFactCheckView: View {
    let check: DisinformationResponse
    var showDetailedView: Bool = false
    @State private var showReason: Bool = false
    
    // Status text from API response
    private var statusText: String {
        let lowercaseResponse = extractExplanation(from: check.explanation).lowercased()
        
        if lowercaseResponse.contains("verdict: true") || check.isVerified {
            return "TRUE"
        } else if lowercaseResponse.contains("verdict: partially true") || check.confidence > 0.7 {
            return "PARTIALLY TRUE"
        } else if lowercaseResponse.contains("verdict: opinion") || lowercaseResponse.contains("verdict: unverifiable") {
            return "UNVERIFIABLE"
        } else if lowercaseResponse.contains("verdict: false") || check.confidence < 0.5 {
            return "FALSE"
        } else {
            return "UNVERIFIABLE"
        }
    }
    
    // Status color
    private var statusColor: Color {
        switch statusText {
        case "TRUE":
            return .green
        case "PARTIALLY TRUE":
            return .orange
        case "UNVERIFIABLE":
            return .yellow
        case "FALSE":
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                
                Text("GALADRIEL FACT CHECK")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(1)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Status indicator
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusColor)
                    )
                    .foregroundColor(.white)
            }
            
            Divider()
                .background(Color.gray.opacity(0.5))
            
            // Main content
            HStack(spacing: 10) {
                // Status icon
                VStack {
                    if statusText == "TRUE" {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 24))
                    } else if statusText == "PARTIALLY TRUE" {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 24))
                    } else if statusText == "UNVERIFIABLE" {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 24))
                    } else {
                        Image(systemName: "xmark.shield.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 24))
                    }
                }
                .frame(width: 30)
                
                // Summary text in English
                Text(getEnglishTitle())
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            // Confidence score
            HStack {
                Text("Confidence:")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                // Progress bar
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    // Foreground
                    RoundedRectangle(cornerRadius: 2)
                        .fill(statusColor)
                        .frame(width: 100 * CGFloat(check.confidence), height: 4)
                }
                .frame(width: 100)
                
                Text("\(Int(check.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Reason pop-up (conditionally shown)
            if showReason {
                ReasonView(explanation: extractExplanation(from: check.explanation))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0.3),
                                    statusColor.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showReason.toggle()
            }
        }
    }
    
    // Get English title based on status
    private func getEnglishTitle() -> String {
        switch statusText {
        case "TRUE":
            return "This information is verified"
        case "PARTIALLY TRUE":
            return "This information is partially true"
        case "UNVERIFIABLE":
            return "This information cannot be verified"
        case "FALSE":
            return "This information is false"
        default:
            return "This information requires verification"
        }
    }
    
    // Extract the full explanation part to find verdict
    private func extractExplanation(from explanation: String) -> String {
        // Attempt to clean up Türkçe headers if they exist
        let cleanText = explanation
            .replacingOccurrences(of: "✅ İçerik Doğrulandı", with: "")
            .replacingOccurrences(of: "❌ Yanlış Bilgi", with: "")
            .replacingOccurrences(of: "⚠️ Kısmen Doğru", with: "")
            .replacingOccurrences(of: "🔍 Bilgi Yetersiz", with: "")
            .replacingOccurrences(of: "🤔 Doğrulanamaz/Kişisel Görüş", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Return the cleaned text
        return cleanText
    }
}

// Reason pop-up view
struct ReasonView: View {
    let explanation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHY?")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            
            Text(explanation)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true) // Allow text to expand vertically
                .multilineTextAlignment(.leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
        )
        .padding(.top, 6)
    }
}

struct GaladrielFactCheckView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // True example
                GaladrielFactCheckView(
                    check: DisinformationResponse(
                        isVerified: true,
                        sources: ["https://example.com/source1"],
                        confidence: 0.95,
                        explanation: "VERDICT: TRUE\n\nThis content has been verified by scientific research."
                    )
                )
                
                // False example
                GaladrielFactCheckView(
                    check: DisinformationResponse(
                        isVerified: false,
                        sources: nil,
                        confidence: 0.2,
                        explanation: "VERDICT: FALSE\n\nExtensive research, including studies by the World Health Organization and the Centers for Disease Control and Prevention, have consistently found no link between vaccines and autism."
                    )
                )
                
                // Partially true example
                GaladrielFactCheckView(
                    check: DisinformationResponse(
                        isVerified: false,
                        sources: nil,
                        confidence: 0.75,
                        explanation: "VERDICT: PARTIALLY TRUE\n\nThis claim contains some accurate information but is also misleading in several aspects."
                    )
                )
            }
            .padding()
        }
    }
} 
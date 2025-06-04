import SwiftUI

struct EmailSuggestionView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.element) { index, suggestion in
                Button(action: {
                    onSelect(suggestion)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "at")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(suggestion)
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                
                if index < suggestions.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.15))
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
} 
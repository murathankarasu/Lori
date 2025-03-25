import SwiftUI

struct EmailSuggestionView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: { onSelect(suggestion) }) {
                        Text(suggestion)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 50)
    }
} 
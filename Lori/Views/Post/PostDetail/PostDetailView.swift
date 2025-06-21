import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PostDetailView: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = PostDetailViewModel()
    @State private var showDeleteAlert = false
    @State private var showCommentSheet = false
    @State private var showDetailedFactCheck = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header ve içerik bölümleri
                        PostHeaderView(post: post)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        PostContentView(post: post)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Dezenformasyon kontrolü görünümü - sadece gerekli durumlarda göster
                        if viewModel.shouldShowDisinformationCheck {
                            disinformationView
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.horizontal)
                        }
                        
                        // Post aksiyonları
                        PostActionsView(
                            post: post,
                            isLiked: viewModel.isLiked,
                            likesCount: viewModel.likesCount,
                            commentsCount: viewModel.comments.count,
                            viewCount: viewModel.viewCount,
                            onLikeTapped: { viewModel.toggleLike() },
                            onCommentTapped: { showCommentSheet = true }
                        )
                        .padding(.horizontal)
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.horizontal)
                        
                        // Yorumlar listesi
                        CommentsListView(comments: viewModel.comments)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: {
                    // Animasyonsuz kapatma
                    withAnimation(.none) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                },
                trailing: deleteButton
            )
        }
        .transition(.identity) // Animasyonsuz geçiş
        .alert("Gönderiyi Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                viewModel.deletePost(post) {
                    withAnimation(.none) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this post?")
        }
        .sheet(isPresented: $showCommentSheet) {
            AddCommentView(post: post)
        }
        .sheet(isPresented: $showDetailedFactCheck) {
            if let check = viewModel.disinformationCheck {
                DetailedFactCheckView(check: check)
            }
        }
        .onAppear {
            viewModel.loadPostDetails(post)
        }
    }
    
    // MARK: - Yardımcı görünümler
    
    @ViewBuilder
    private var deleteButton: some View {
        if post.userId == Auth.auth().currentUser?.uid {
            Button(action: {
                showDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var disinformationView: some View {
        Group {
            if let check = viewModel.disinformationCheck {
                Button(action: {
                    showDetailedFactCheck = true
                }) {
                    GaladrielFactCheckView(check: check)
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            } else if viewModel.isCheckingDisinformation {
                disinformationLoadingView
            }
        }
    }
    
    @ViewBuilder
    private var disinformationLoadingView: some View {
        HStack {
            ProgressView()
                .tint(.white)
            
            Text("Galadriel is fact checking...")
                .font(.footnote)
                .foregroundColor(.white)
                .padding(.leading, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

// Detailed fact check view for sheet presentation
struct DetailedFactCheckView: View {
    let check: DisinformationResponse
    @Environment(\.presentationMode) var presentationMode
    
    // Status text from API response
    private var statusText: String {
        let lowercaseResponse = check.explanation.lowercased()
        
        if lowercaseResponse.contains("verdict: true") {
            return "TRUE"
        } else if lowercaseResponse.contains("verdict: partially true") {
            return "PARTIALLY TRUE"
        } else if lowercaseResponse.contains("verdict: opinion") || lowercaseResponse.contains("verdict: unverifiable") {
            return "UNVERIFIABLE"
        } else if lowercaseResponse.contains("verdict: false") {
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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with status
                    HStack {
                        Text("GALADRIEL VERDICT")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(statusText)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(statusColor))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black)
                    
                    // Explanation section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI ANALYSIS")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        
                        Text(extractExplanation())
                            .font(.body)
                            .foregroundColor(.white)
                            .lineSpacing(4)
                        
                        // Confidence score
                        HStack {
                            Text("CONFIDENCE SCORE")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("\(Int(check.confidence * 100))%")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(statusColor)
                        }
                        .padding(.top, 8)
                        
                        // Progress bar
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                            
                            // Foreground
                            RoundedRectangle(cornerRadius: 4)
                                .fill(statusColor)
                                .frame(width: UIScreen.main.bounds.width * 0.8 * CGFloat(check.confidence), height: 8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                    
                    // Sources if available
                    if let sources = check.sources, !sources.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SOURCES")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            
                            ForEach(sources, id: \.self) { source in
                                if let url = URL(string: source) {
                                    Link(destination: url) {
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
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Fact Check", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // Extract the explanation part only
    private func extractExplanation() -> String {
        // Try to find the verdict statement
        if let verdictRange = check.explanation.range(of: "VERDICT:", options: [.caseInsensitive]) {
            // Extract the explanation part after the verdict
            let startIndex = verdictRange.upperBound
            
            // Skip to the next line after the verdict
            if let newlineRange = check.explanation[startIndex...].range(of: "\n") {
                let explanationStartIndex = newlineRange.upperBound
                return String(check.explanation[explanationStartIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // If no verdict found, return the full text
        return check.explanation
    }
} 
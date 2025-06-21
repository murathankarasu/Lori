import SwiftUI
import FirebaseAuth // Required for Auth.auth() usage
import FirebaseFirestore // Required for Timestamp usage

// Function to dismiss keyboard
extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct PublishButton: View {
    @ObservedObject var viewModel: CreatePostViewModel
    @ObservedObject var contentValidator: ContentValidationViewModel
    @ObservedObject var mediaManager: MediaManagerViewModel
    @Binding var showHateSpeechAlert: Bool
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isPublishing = false
    @State private var showPublishingOverlay = false
    @State private var publishStatus: PublishLoadingView.PublishStatus = .loading
    
    var body: some View {
        ZStack {
            Button(action: {
                print("\n=== Publish Button Tapped ===")
                print("Content: \(viewModel.postContent)")
                
                // Show loading screen and dismiss keyboard
                publishStatus = .loading
                UIApplication.shared.dismissKeyboard()
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPublishingOverlay = true
                }
                
                Task {
                    do {
                        // Hate speech check
                        let (isHateSpeech, category, _) = try await viewModel.checkHateSpeech()
                        
                        if isHateSpeech {
                            // Hate speech detected
                            viewModel.errorMessage = "Your message violates our policies. Category: \(category)"
                            
                            // Update status for error display
                            DispatchQueue.main.async {
                                publishStatus = .failure
                            }
                        } else {
                            // No hate speech, continue processing
                            viewModel.errorMessage = ""
                            
                            // Media processing
                            print("Starting media processing...")
                            await viewModel.processMedia()
                            
                            // Create post
                            try await viewModel.createPost()
                            
                            // Show success status
                            DispatchQueue.main.async {
                                publishStatus = .success
                                
                                // Close screen after 2 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    dismiss() // Close CreatePostView
                                }
                            }
                        }
                    } catch {
                        // Error occurred during processing
                        viewModel.errorMessage = error.localizedDescription
                        viewModel.showError = true
                        
                        // Update status for error display
                        DispatchQueue.main.async {
                            publishStatus = .failure
                        }
                    }
                }
            }) {
                // Button appearance - black icon on white background
                HStack {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(width: 100, height: 40)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
            .disabled(viewModel.postContent.isEmpty || isPublishing)
        }
        // Full screen loading overlay - moved outside ZStack
        .fullScreenCover(isPresented: $showPublishingOverlay) {
            PublishLoadingView(
                status: $publishStatus,
                isPresented: $showPublishingOverlay,
                errorMessage: viewModel.errorMessage
            )
        }
    }
}

// Note: Previous FollowingFeedView definition removed. Original FollowingFeedView already exists in another file.

#Preview {
    PublishButton(
        viewModel: CreatePostViewModel(),
        contentValidator: ContentValidationViewModel(),
        mediaManager: MediaManagerViewModel(),
        showHateSpeechAlert: .constant(false)
    )
} 

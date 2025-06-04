import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

struct AddCommentView: View {
    let post: Post
    @StateObject private var viewModel = AddCommentViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var profileImageUrl: String?
    @State private var username: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
                
                Spacer()
                
                Text("Add Comment")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.addComment(to: post) { success in
                            if success { dismiss() }
                        }
                    }
                }) {
                    if viewModel.isPosting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.canPost ? .white : .gray.opacity(0.7))
                    }
                }
                .disabled(!viewModel.canPost)
            }
            .padding(.vertical, 16)
            .padding(.horizontal)
            .background(Color.black.opacity(0.8))
            
            Divider()
                .background(Color.gray.opacity(0.5))
            
            // User information
            HStack(spacing: 12) {
                // Profile photo
                profileImageView
                    .frame(width: 40, height: 40)
                
                Text(username)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            
            // Comment area
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 120)
                
                if viewModel.commentText.isEmpty {
                    Text("Write your comment...")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }
                
                TextEditor(text: $viewModel.commentText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(height: 120)
                    .padding(8)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            // Character counter and hate speech indicator
            HStack {
                if viewModel.isCheckingHateSpeech {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Checking for hate speech...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else if viewModel.isHateSpeechDetected {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("Hate speech detected!")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                Spacer()
                
                Text("\(viewModel.commentText.count)/\(viewModel.maxContentLength)")
                    .foregroundColor(viewModel.commentText.count > viewModel.maxContentLength ? .red : .gray)
                    .font(.caption)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            loadUserProfile()
        }
        .alert("Nefret Söylemi Tespit Edildi", isPresented: $viewModel.showHateSpeechWarning) {
            Button("OK", role: .cancel) { viewModel.showHateSpeechWarning = false }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("Hata", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { viewModel.showError = false }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var profileImageView: some View {
        Group {
            if let profileUrl = profileImageUrl, !profileUrl.isEmpty, let url = URL(string: profileUrl) {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func loadUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.username = data["username"] as? String ?? "Kullanıcı"
                    self.profileImageUrl = data["profileImageUrl"] as? String
                }
            }
        }
    }
} 

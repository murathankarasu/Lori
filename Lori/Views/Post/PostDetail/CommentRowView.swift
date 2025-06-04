import SwiftUI
import Kingfisher
import FirebaseFirestore

struct CommentRowView: View {
    let comment: Comment
    @State private var profileImageUrl: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let profileImageUrl = profileImageUrl, !profileImageUrl.isEmpty {
                    KFImage(URL(string: profileImageUrl))
                        .placeholder {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.white)
                        }
                        .cacheMemoryOnly(false)
                        .fade(duration: 0.25)
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 50, height: 50)))
                        .loadDiskFileSynchronously()
                        .resizable()
                        .scaledToFill()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                }
                
                Text(comment.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(comment.relativeTimeString)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(comment.content)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .onAppear {
            fetchUserProfileImage()
        }
    }
    
    private func fetchUserProfileImage() {
        // Yorum yapan kullanıcının profil resmini getir
        let db = Firestore.firestore()
        db.collection("users").document(comment.userId).getDocument { snapshot, error in
            if let data = snapshot?.data(), let imageUrl = data["profileImageUrl"] as? String {
                profileImageUrl = imageUrl
            }
        }
    }
} 
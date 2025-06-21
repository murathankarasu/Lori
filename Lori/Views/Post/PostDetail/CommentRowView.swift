import SwiftUI
import Kingfisher
import FirebaseFirestore

struct CommentRowView: View {
    let comment: Comment
    @State private var profileImageUrl: String?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Profil fotoğrafı
                if let profileImageUrl = profileImageUrl, !profileImageUrl.isEmpty {
                    KFImage(URL(string: profileImageUrl))
                        .placeholder {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                            .foregroundColor(.gray.opacity(0.4))
                        }
                        .cacheMemoryOnly(false)
                        .fade(duration: 0.25)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 36, height: 36)))
                        .loadDiskFileSynchronously()
                        .resizable()
                        .scaledToFill()
                    .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    .shadow(radius: 2, y: 1)
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.gray.opacity(0.4))
                }
                
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                Text(comment.username)
                    .font(.subheadline)
                        .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                    Text("·")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 2)
                
                Text(comment.relativeTimeString)
                    .font(.caption)
                    .foregroundColor(.gray)
                    Spacer()
            }
            
            Text(comment.content)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
                .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
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
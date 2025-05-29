import SwiftUI
import Kingfisher
import FirebaseAuth

struct PostHeaderView: View {
    let post: Post
    
    var body: some View {
        HStack(spacing: 12) {
            // Mevcut kullanıcı kimliğini kontrol et
            if let currentUserId = Auth.auth().currentUser?.uid, post.userId != currentUserId {
                // Başka bir kullanıcının profili ise, profile gitme bağlantısı göster
                NavigationLink(destination: ProfileView(userId: post.userId)) {
                    profileImageView
                }
            } else {
                // Kendi profili ise, yalnızca görüntüyü göster (bağlantısız)
                profileImageView
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Mevcut kullanıcı kimliğini kontrol et
                if let currentUserId = Auth.auth().currentUser?.uid, post.userId != currentUserId {
                    // Başka bir kullanıcının profili ise, profile gitme bağlantısı göster
                    NavigationLink(destination: ProfileView(userId: post.userId)) {
                        Text(post.username)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                } else {
                    // Kendi profili ise, yalnızca kullanıcı adını göster (bağlantısız)
                    Text(post.username)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Text(post.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // Profil görüntüsü için yardımcı görünüm
    private var profileImageView: some View {
        Group {
            if let profileImageUrl = post.profileImageUrl, !profileImageUrl.isEmpty {
                KFImage(URL(string: profileImageUrl))
                    .placeholder {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.white)
                    }
                    .cacheMemoryOnly(false)
                    .fade(duration: 0.25)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 80, height: 80)) |> RoundCornerImageProcessor(cornerRadius: 20))
                    .loadDiskFileSynchronously()
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
            }
        }
    }
} 
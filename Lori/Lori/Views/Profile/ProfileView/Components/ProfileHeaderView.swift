import SwiftUI
import Kingfisher

struct ProfileHeaderView: View {
    let username: String
    let bio: String
    let profileImageUrl: String?
    @Binding var showEditProfile: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Profil Resmi
            if let imageUrl = profileImageUrl {
                KFImage(URL(string: imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
            
            // Kullanıcı Adı
            Text(username)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Biyografi
            if !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Profili Düzenle Butonu
            Button(action: { showEditProfile = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                    Text("Profili Düzenle")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.black)
                .frame(width: 180, height: 36)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 8)
        }
        .padding(.vertical)
    }
}
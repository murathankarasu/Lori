import SwiftUI

struct ProfileStatsView: View {
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
    let onFollowersClick: () -> Void
    let onFollowingClick: () -> Void
    
    var body: some View {
        HStack(spacing: 30) {
            VStack {
                Text("\(postsCount)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Gönderi")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Button(action: onFollowersClick) {
                VStack {
                    Text("\(followersCount)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Takipçi")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Button(action: onFollowingClick) {
                VStack {
                    Text("\(followingCount)")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Takip")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical)
    }
} 
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Kingfisher

struct CommentsListView: View {
    let comments: [Comment]
    @State private var isDeleting = false
    @State private var deletingCommentId: String?
    @State private var userProfiles: [String: UserProfile] = [:]
    
    struct UserProfile {
        let username: String
        let profileImageUrl: String?
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if comments.isEmpty {
                emptyCommentsView
            } else {
                Text("Yorumlar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                ForEach(comments) { comment in
                    commentView(for: comment)
                    
                    if comment.id != comments.last?.id {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .onAppear {
            loadUserProfiles()
        }
    }
    
    private var emptyCommentsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.gray)
                .padding(.top, 20)
            
            Text("Henüz yorum yok")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("İlk yorumu sen yap!")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func commentView(for comment: Comment) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Profil resmi
            profileImageView(userId: comment.userId)
                .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 6) {
                // Kullanıcı adı ve zaman
                HStack {
                    Text(userProfiles[comment.userId]?.username ?? comment.username)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(timeAgo(from: comment.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Yorum içeriği
                Text(comment.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Silme butonu - sadece kendi yorumları için göster
                if comment.userId == Auth.auth().currentUser?.uid {
                    HStack {
                        Spacer()
                        
                        if isDeleting && deletingCommentId == comment.id {
                            ProgressView()
                                .scaleEffect(0.7)
                                .padding(.top, 4)
                        } else {
                            Button(action: { deleteComment(comment) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                    Text("Sil")
                                        .font(.caption)
                                }
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.top, 4)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func profileImageView(userId: String) -> some View {
        Group {
            if let profileUrl = userProfiles[userId]?.profileImageUrl, !profileUrl.isEmpty, let url = URL(string: profileUrl) {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.gray)
                    }
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func loadUserProfiles() {
        let db = Firestore.firestore()
        let userIds = Set(comments.map { $0.userId })
        
        for userId in userIds {
            if userProfiles[userId] == nil {
                db.collection("users").document(userId).getDocument { snapshot, error in
                    if let data = snapshot?.data() {
                        let username = data["username"] as? String ?? "Kullanıcı"
                        let profileImageUrl = data["profileImageUrl"] as? String
                        
                        DispatchQueue.main.async {
                            userProfiles[userId] = UserProfile(
                                username: username,
                                profileImageUrl: profileImageUrl
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let year = components.year, year >= 1 {
            return "\(year) yıl önce"
        }
        if let month = components.month, month >= 1 {
            return "\(month) ay önce"
        }
        if let week = components.weekOfYear, week >= 1 {
            return "\(week) hafta önce"
        }
        if let day = components.day, day >= 1 {
            return "\(day) gün önce"
        }
        if let hour = components.hour, hour >= 1 {
            return "\(hour) saat önce"
        }
        if let minute = components.minute, minute >= 1 {
            return "\(minute) dakika önce"
        }
        return "Az önce"
    }
    
    private func deleteComment(_ comment: Comment) {
        guard let postId = comment.postId as String?, let commentId = comment.id else { return }
        isDeleting = true
        deletingCommentId = commentId
        let db = Firestore.firestore()
        db.collection("posts").document(postId).collection("comments").document(commentId).delete { error in
            isDeleting = false
            deletingCommentId = nil
            if error == nil {
                // commentsCount alanını azalt
                db.collection("posts").document(postId).updateData([
                    "commentsCount": FieldValue.increment(Int64(-1))
                ])
            }
        }
    }
} 
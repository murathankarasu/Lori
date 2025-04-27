import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CommentsListView: View {
    let comments: [Comment]
    @State private var isDeleting = false
    @State private var deletingCommentId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(comments) { comment in
                HStack(alignment: .top) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(comment.username)
                                .font(.subheadline).bold()
                                .foregroundColor(.white)
                            Spacer()
                            if comment.userId == Auth.auth().currentUser?.uid {
                                if isDeleting && deletingCommentId == comment.id {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Button(action: { deleteComment(comment) }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        Text(comment.content)
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal)
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
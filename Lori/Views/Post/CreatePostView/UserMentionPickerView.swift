import SwiftUI

struct UserMentionPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedUser: String?
    
    private let users = ["@user1", "@user2", "@user3", "@user4", "@user5"]
    
    var body: some View {
        NavigationView {
            List(users, id: \.self) { user in
                Button(action: {
                    selectedUser = user
                    dismiss()
                }) {
                    Text(user)
                        .foregroundColor(.white)
                }
            }
            .navigationTitle("Kullanıcı Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    UserMentionPickerView(selectedUser: .constant(nil))
} 
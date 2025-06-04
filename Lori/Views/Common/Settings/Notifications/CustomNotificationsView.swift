import SwiftUI

struct CustomNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var customNotifications: [CustomNotification] = []
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Custom Notification List
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Custom Notifications")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ForEach(customNotifications) { notification in
                            CustomNotificationRow(notification: notification)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Add New Notification Button
                    Button(action: {
                        // Add new notification
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                            
                            Text("Add New Notification")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Custom Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    // Save custom notifications
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
    }
}

struct CustomNotificationRow: View {
    let notification: CustomNotification
    @State private var isEnabled = true
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(notification.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .tint(.white)
        }
    }
}

struct CustomNotification: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    var isEnabled: Bool
} 
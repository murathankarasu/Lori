import SwiftUI
import Kingfisher

struct UserCell: View {
    let user: User
    let onTap: () -> Void
    let onRemove: (() -> Void)?
    let showRemoveButton: Bool
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack(spacing: 16) {
                // Profile image - Improved loading
                KFImage(URL(string: user.profileImageUrl ?? ""))
                    .cacheMemoryOnly(false)
                    .cacheOriginalImage()
                    .fade(duration: 0.2)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 108, height: 108)))
                    .loadDiskFileSynchronously()
                    .backgroundDecode()
                    .onProgress { receivedSize, totalSize in
                        // Progress handling if needed
                    }
                    .onSuccess { result in
                        // Success handling if needed
                    }
                    .onFailure { error in
                        print("Profile image load failed for user \(user.username): \(error)")
                    }
                    .placeholder {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.1),
                                            Color.white.opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 54, height: 54)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 54, height: 54)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    // Username and verification badge
                    HStack(spacing: 6) {
                        Text(user.username)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Bio
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Follower count
                    if user.followers > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                            
                            Text("\(formatFollowerCount(user.followers)) followers")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                // Remove button
                if let onRemove = onRemove, showRemoveButton {
                    Button(action: {
                        onRemove()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Chevron for navigation
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatFollowerCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000.0)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        } else {
            return "\(count)"
        }
    }
} 
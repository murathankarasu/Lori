import Foundation
import SwiftUI
import Combine
import Kingfisher
import FirebaseAuth
import FirebaseFirestore

// MARK: - User Service
class UserService {
    func getUser(userId: String) async throws -> User? {
        let db = Firestore.firestore()
        let userDoc = try await db.collection("users").document(userId).getDocument()
        
        guard let data = userDoc.data() else { return nil }
        
        // Parse timestamp
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }
        
        return User(
            id: userId,
            username: data["username"] as? String ?? "",
            email: data["email"] as? String ?? "",
            profileImageUrl: data["profileImageUrl"] as? String,
            bio: data["bio"] as? String ?? "",
            followers: data["followers"] as? Int ?? 0,
            following: data["following"] as? Int ?? 0,
            createdAt: createdAt,
            isVerified: data["isVerified"] as? Bool ?? false,
            usernameLower: data["usernameLower"] as? String ?? (data["username"] as? String ?? "").lowercased()
        )
    }
}

// MARK: - Cache Manager
class CacheManager: ObservableObject {
    static let shared = CacheManager()
    
    private var featuredPostsCache: [Post] = []
    private var followingPostsCache: [Post] = []
    private var lastFeaturedUpdate: Date?
    private var lastFollowingUpdate: Date?
    private let cacheExpirationTime: TimeInterval = 120 // 2 dakika
    
    // UserDefaults anahtarları
    private let featuredCacheKey = "featured_posts_cache"
    private let followingCacheKey = "following_posts_cache"
    private let featuredUpdateKey = "featured_last_update"
    private let followingUpdateKey = "following_last_update"
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
    
    private init() {
        loadCacheFromUserDefaults()
    }
    
    // MARK: - Featured Posts Cache
    func getFeaturedPosts() -> [Post] {
        return featuredPostsCache
    }
    
    func setCachedFeaturedPosts(_ posts: [Post]) {
        featuredPostsCache = posts
        lastFeaturedUpdate = Date()
        saveFeaturedCacheToUserDefaults()
    }
    
    func isFeaturedCacheValid() -> Bool {
        guard let lastUpdate = lastFeaturedUpdate else { return false }
        return Date().timeIntervalSince(lastUpdate) < cacheExpirationTime
    }
    
    func clearFeaturedCache() {
        featuredPostsCache.removeAll()
        lastFeaturedUpdate = nil
        UserDefaults.standard.removeObject(forKey: featuredCacheKey)
        UserDefaults.standard.removeObject(forKey: featuredUpdateKey)
    }
    
    // MARK: - Following Posts Cache
    func getFollowingPosts() -> [Post] {
        return followingPostsCache
    }
    
    func setCachedFollowingPosts(_ posts: [Post]) {
        followingPostsCache = posts
        lastFollowingUpdate = Date()
        saveFollowingCacheToUserDefaults()
    }
    
    func isFollowingCacheValid() -> Bool {
        guard let lastUpdate = lastFollowingUpdate else { return false }
        return Date().timeIntervalSince(lastUpdate) < cacheExpirationTime
    }
    
    func clearFollowingCache() {
        followingPostsCache.removeAll()
        lastFollowingUpdate = nil
        UserDefaults.standard.removeObject(forKey: followingCacheKey)
        UserDefaults.standard.removeObject(forKey: followingUpdateKey)
    }
    
    // MARK: - Clear All Cache
    func clearAllCache() {
        clearFeaturedCache()
        clearFollowingCache()
        clearImageCache()
        print("🧹 All cache cleared successfully")
    }
    
    // MARK: - Image Cache
    func clearImageCache() {
        // Clear Kingfisher cache
        KingfisherManager.shared.cache.clearMemoryCache()
        KingfisherManager.shared.cache.clearDiskCache { 
            print("🖼️ Kingfisher disk cache cleared")
        }
        print("🖼️ Image cache cleared")
    }
    
    // MARK: - UserDefaults Persistence
    private func loadCacheFromUserDefaults() {
        // Featured posts cache
        if let cachedData = UserDefaults.standard.data(forKey: featuredCacheKey),
           let decodedPosts = try? JSONDecoder().decode([Post].self, from: cachedData) {
            featuredPostsCache = decodedPosts
            lastFeaturedUpdate = UserDefaults.standard.object(forKey: featuredUpdateKey) as? Date
        }
        
        // Following posts cache
        if let cachedData = UserDefaults.standard.data(forKey: followingCacheKey),
           let decodedPosts = try? JSONDecoder().decode([Post].self, from: cachedData) {
            followingPostsCache = decodedPosts
            lastFollowingUpdate = UserDefaults.standard.object(forKey: followingUpdateKey) as? Date
        }
    }
    
    private func saveFeaturedCacheToUserDefaults() {
        if let encodedData = try? JSONEncoder().encode(featuredPostsCache) {
            UserDefaults.standard.set(encodedData, forKey: featuredCacheKey)
            UserDefaults.standard.set(lastFeaturedUpdate, forKey: featuredUpdateKey)
        }
    }
    
    private func saveFollowingCacheToUserDefaults() {
        if let encodedData = try? JSONEncoder().encode(followingPostsCache) {
            UserDefaults.standard.set(encodedData, forKey: followingCacheKey)
            UserDefaults.standard.set(lastFollowingUpdate, forKey: followingUpdateKey)
        }
    }
    
    // MARK: - Cache Statistics
    func getCacheInfo() -> (featuredCount: Int, followingCount: Int, featuredAge: TimeInterval?, followingAge: TimeInterval?) {
        let featuredAge = lastFeaturedUpdate?.timeIntervalSinceNow
        let followingAge = lastFollowingUpdate?.timeIntervalSinceNow
        
        return (
            featuredCount: featuredPostsCache.count,
            followingCount: followingPostsCache.count,
            featuredAge: featuredAge,
            followingAge: followingAge
        )
    }
    
    // MARK: - Debug Functions
    func printCacheStatus() {
        let info = getCacheInfo()
        print("💾 Cache Status:")
        print("📝 Featured Posts: \(info.featuredCount) posts")
        print("📝 Following Posts: \(info.followingCount) posts")
        
        if let featuredAge = info.featuredAge {
            let minutes = Int(-featuredAge / 60)
            print("⏰ Featured Cache Age: \(minutes) dakika")
            print("✅ Featured Cache Valid: \(isFeaturedCacheValid())")
        } else {
            print("❌ Featured Cache: No timestamp")
        }
        
        if let followingAge = info.followingAge {
            let minutes = Int(-followingAge / 60)
            print("⏰ Following Cache Age: \(minutes) dakika")
            print("✅ Following Cache Valid: \(isFollowingCacheValid())")
        } else {
            print("❌ Following Cache: No timestamp")
        }
    }
    
    // MARK: - Image Preloading
    func preloadImages() async {
        print("🖼️ Starting image preloading...")
        
        // Configure Kingfisher cache with reasonable sizes
        let cache = KingfisherManager.shared.cache
        cache.memoryStorage.config.totalCostLimit = 150 * 1024 * 1024 // 150MB memory cache
        cache.diskStorage.config.sizeLimit = 400 * 1024 * 1024 // 400MB disk cache
        
        // Get current user's profile image
        if let currentUser = Auth.auth().currentUser {
            let userService = UserService()
            if let user = try? await userService.getUser(userId: currentUser.uid) {
                if let profileImageUrl = user.profileImageUrl {
                    await preloadImage(url: profileImageUrl, isHighPriority: true)
                }
            }
        }
        
        // Preload featured posts images
        let featuredPosts = getFeaturedPosts()
        await preloadPostImages(posts: featuredPosts, isHighPriority: true)
        
        // Preload following posts images
        let followingPosts = getFollowingPosts()
        await preloadPostImages(posts: followingPosts, isHighPriority: true)
        
        // Preload all user profile images from posts
        await preloadAllUserProfileImages(posts: featuredPosts + followingPosts)
        
        print("✅ Image preloading completed")
    }
    
    private func preloadPostImages(posts: [Post], isHighPriority: Bool) async {
        for post in posts {
            // Preload post image
            if let imageUrl = post.imageUrl {
                await preloadImage(url: imageUrl, isHighPriority: isHighPriority)
            }
            
            // Preload user profile image
            if let profileImageUrl = post.profileImageUrl {
                await preloadImage(url: profileImageUrl, isHighPriority: isHighPriority)
            }
        }
    }
    
    private func preloadAllUserProfileImages(posts: [Post]) async {
        let userIds = Set(posts.map { $0.userId })
        let userService = UserService()
        
        for userId in userIds {
            if let user = try? await userService.getUser(userId: userId) {
                if let profileImageUrl = user.profileImageUrl {
                    await preloadImage(url: profileImageUrl, isHighPriority: false)
                }
            }
        }
    }
    
    private func preloadImage(url: String, isHighPriority: Bool) async {
        guard let imageUrl = URL(string: url) else { return }
        
        do {
            // Configure options for aggressive caching
            let options: KingfisherOptionsInfo = [
                .backgroundDecode, // Decode in background
                .scaleFactor(UIScreen.main.scale), // Use device scale factor
                .transition(.fade(0.2)) // Smooth fade transition
            ]
            
            // Preload and cache the image
            let _ = try await KingfisherManager.shared.retrieveImage(
                with: imageUrl,
                options: options
            )
            
            if isHighPriority {
                print("✅ Preloaded high priority image: \(url)")
            } else {
                print("✅ Preloaded image: \(url)")
            }
        } catch {
            print("❌ Failed to preload image: \(url)")
        }
    }
    
    // MARK: - Cache Management
    func getCacheSize() -> (memorySize: Int, diskSize: Int) {
        let cache = KingfisherManager.shared.cache
        return (
            memorySize: Int(cache.memoryStorage.config.totalCostLimit),
            diskSize: Int(cache.diskStorage.config.sizeLimit)
        )
    }
}

// MARK: - Shared ViewModel Manager
@MainActor
class SharedViewModelManager: ObservableObject {
    static let shared = SharedViewModelManager()
    
    private var _featuredViewModel: FeaturedFeedViewModel?
    private var _followingViewModel: FollowingFeedViewModel?
    
    nonisolated private init() {}
    
    func getFeaturedViewModel() -> FeaturedFeedViewModel {
        if let existing = _featuredViewModel {
            return existing
        } else {
            let newViewModel = FeaturedFeedViewModel()
            _featuredViewModel = newViewModel
            return newViewModel
        }
    }
    
    func getFollowingViewModel() -> FollowingFeedViewModel {
        if let existing = _followingViewModel {
            return existing
        } else {
            let newViewModel = FollowingFeedViewModel()
            _followingViewModel = newViewModel
            return newViewModel
        }
    }
    
    func clearViewModels() {
        _featuredViewModel = nil
        _followingViewModel = nil
    }
} 
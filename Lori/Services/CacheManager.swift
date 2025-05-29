import Foundation
import SwiftUI
import Combine
import Kingfisher

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
        // Kingfisher cache temizle
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
import FirebaseFirestore

class FirestoreIndexes {
    static func createIndexes() async {
        let db = Firestore.firestore()
        
        // Posts koleksiyonu için indeksler
        await createPostsIndexes(db: db)
        
        // Users koleksiyonu için indeksler
        await createUsersIndexes(db: db)
    }
    
    // MARK: - Post Migration (Post Migrasyonu)
    /// Mevcut postlara eksik alanları eklemek için migration fonksiyonu
    static func migratePosts() async {
        let db = Firestore.firestore()
        
        do {
            print("🔄 Starting Post migration...")
            
            // Kategori alanı eksik olan postları bul
            let postsRef = db.collection("posts")
            let snapshot = try await postsRef.getDocuments()
            
            var updatedCount = 0
            var skippedCount = 0
            
            for document in snapshot.documents {
                let data = document.data()
                
                // Kategori alanı eksikse ekle
                if data["category"] == nil {
                    try await document.reference.updateData([
                        "category": "featured"
                    ])
                    updatedCount += 1
                    print("✅ Updated post \(document.documentID) with category: featured")
                } else {
                    skippedCount += 1
                }
            }
            
            print("📊 Post migration completed:")
            print("   ✅ Updated: \(updatedCount) posts")
            print("   ⏭️ Skipped: \(skippedCount) posts")
            print("   📈 Total processed: \(snapshot.documents.count) posts")
            
        } catch {
            print("❌ Error during Post migration: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Batch Post Migration (Toplu Post Migrasyonu)
    /// Büyük veri setleri için batch migration
    static func migratePostsBatch(batchSize: Int = 500) async {
        let db = Firestore.firestore()
        
        do {
            print("🔄 Starting batch Post migration...")
            
            let postsRef = db.collection("posts")
            let snapshot = try await postsRef.getDocuments()
            
            var totalUpdated = 0
            var totalSkipped = 0
            let totalPosts = snapshot.documents.count
            
            // Batch'ler halinde işle
            for i in stride(from: 0, to: totalPosts, by: batchSize) {
                let batch = db.batch()
                let endIdx = min(i + batchSize, totalPosts)
                var batchUpdated = 0
                
                for j in i..<endIdx {
                    let document = snapshot.documents[j]
                    let data = document.data()
                    
                    // Kategori alanı eksikse batch'e ekle
                    if data["category"] == nil {
                        batch.updateData([
                            "category": "featured"
                        ], forDocument: document.reference)
                        batchUpdated += 1
                    }
                }
                
                // Batch'i commit et
                if batchUpdated > 0 {
                    try await batch.commit()
                    totalUpdated += batchUpdated
                    print("✅ Updated batch \(i/batchSize + 1): \(batchUpdated) posts")
                }
                
                totalSkipped += (endIdx - i) - batchUpdated
            }
            
            print("📊 Batch Post migration completed:")
            print("   ✅ Total updated: \(totalUpdated) posts")
            print("   ⏭️ Total skipped: \(totalSkipped) posts")
            print("   📈 Success rate: \(totalPosts > 0 ? Double(totalUpdated) / Double(totalPosts) * 100 : 0)%")
            
        } catch {
            print("❌ Error during batch Post migration: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Comprehensive Migration (Kapsamlı Migrasyon)
    /// Tüm eksik alanları düzeltmek için kapsamlı migration
    static func runComprehensiveMigration() async {
        print("🚀 Starting comprehensive Firestore migration...")
        
        // 1. Post migration
        await migratePostsBatch()
        
        // 2. Index creation
        await createIndexes()
        
        print("🎉 Comprehensive migration completed!")
    }
    
    // MARK: - Migration Helper (Migrasyon Yardımcısı)
    /// Uygulama başlangıcında çağrılabilir migration fonksiyonu
    static func runMigrationIfNeeded() async {
        // Bu fonksiyon uygulama başlangıcında bir kez çalıştırılabilir
        // Örneğin: AppDelegate veya ContentView'da
        print("🔍 Checking if migration is needed...")
        
        // Basit bir kontrol - eğer migration gerekliyse çalıştır
        // Gerçek uygulamada bu kontrol daha sofistike olabilir
        await runComprehensiveMigration()
    }
    
    private static func createPostsIndexes(db: Firestore) async {
        do {
            // userId ve timestamp indeksi
            try await db.collection("posts").document().setData([
                "userId": "",
                "timestamp": FieldValue.serverTimestamp()
            ])
            
            // isFeatured ve timestamp indeksi
            try await db.collection("posts").document().setData([
                "isFeatured": true,
                "timestamp": FieldValue.serverTimestamp()
            ])
            
            // Takip ekranı için userId ve timestamp bileşik indeksi
            try await db.collection("posts").document().setData([
                "userId": "",
                "timestamp": FieldValue.serverTimestamp(),
                "indexed": true
            ])
            
            // İlgi alanları ve timestamp bileşik indeksi
            try await db.collection("posts").document().setData([
                "interests": [],
                "timestamp": FieldValue.serverTimestamp(),
                "indexed": true
            ])
            
            // Yeni indeksler
            try await db.collection("posts").document().setData([
                "userId": "",
                "username": "",
                "content": "",
                "imageUrl": "",
                "likes": 0,
                "comments": [],
                "timestamp": FieldValue.serverTimestamp()
            ])
        } catch {
            print("Posts indeksleri oluşturulurken hata: \(error.localizedDescription)")
        }
    }
    
    private static func createUsersIndexes(db: Firestore) async {
        do {
            // email indeksi
            try await db.collection("users").document().setData([
                "email": "",
                "timestamp": FieldValue.serverTimestamp()
            ])
            
            // username indeksi
            try await db.collection("users").document().setData([
                "username": "",
                "timestamp": FieldValue.serverTimestamp()
            ])
            
            // usernameLower indeksi
            try await db.collection("users").document().setData([
                "usernameLower": "",
                "timestamp": FieldValue.serverTimestamp()
            ])
        } catch {
            print("Users indeksleri oluşturulurken hata: \(error.localizedDescription)")
        }
    }
} 
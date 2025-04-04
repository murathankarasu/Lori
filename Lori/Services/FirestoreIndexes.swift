import FirebaseFirestore

class FirestoreIndexes {
    static func createIndexes() async {
        let db = Firestore.firestore()
        
        // Posts koleksiyonu için indeksler
        await createPostsIndexes(db: db)
        
        // Users koleksiyonu için indeksler
        await createUsersIndexes(db: db)
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
        } catch {
            print("Users indeksleri oluşturulurken hata: \(error.localizedDescription)")
        }
    }
} 
import Foundation

// Array'i belirli boyutlarda parçalara ayıran extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        // Stride fonksiyonu ile başlangıç indekslerini oluştur
        return stride(from: 0, to: count, by: size).map {
            // Her başlangıç indeksi için alt dizi oluştur
            // Swift.min kullanarak dizinin sonunu aşmamayı garantile
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
} 
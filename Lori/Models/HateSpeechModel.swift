import Foundation
import NaturalLanguage
import CoreML

class HateSpeechModel {
    static let shared = HateSpeechModel()
    
    private let model: HateSpeechClassifier?
    private let tokenizer = NLTokenizer(unit: .word)
    
    private init() {
        do {
            model = try HateSpeechClassifier()
        } catch {
            print("Model yüklenirken hata oluştu: \(error)")
            model = nil
        }
    }
    
    func checkHateSpeech(text: String) -> Bool {
        guard let model = model else {
            print("Model yüklenemedi")
            return false
        }
        
        // Metni tokenize et
        tokenizer.string = text
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            if let token = String(text[range]).lowercased() as String? {
                tokens.append(token)
            }
            return true
        }
        
        // Metni birleştir
        let processedText = tokens.joined(separator: " ")
        
        do {
            let prediction = try model.prediction(text: processedText)
            return prediction.label == "hate"
        } catch {
            print("Tahmin yapılırken hata oluştu: \(error)")
            return false
        }
    }
} 
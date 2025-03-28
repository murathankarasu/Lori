import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import pickle
import os

def load_model():
    # Model ve tokenizer'ı yükle
    model_path = "model"  # Model klasörü
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model klasörü bulunamadı: {model_path}")
        
    model = AutoModelForSequenceClassification.from_pretrained(model_path)
    tokenizer = AutoTokenizer.from_pretrained(model_path)
    
    # Label encoder'ı yükle
    label_encoder_path = os.path.join(model_path, "label_encoder.pkl")
    if not os.path.exists(label_encoder_path):
        raise FileNotFoundError(f"Label encoder dosyası bulunamadı: {label_encoder_path}")
        
    with open(label_encoder_path, "rb") as f:
        label_encoder = pickle.load(f)
    
    return model, tokenizer, label_encoder

def predict_text(text, model, tokenizer, label_encoder):
    # Metni tokenize et
    inputs = tokenizer(text, truncation=True, padding=True, max_length=128, return_tensors="pt")
    
    # Tahmin yap
    model.eval()
    with torch.no_grad():
        outputs = model(**inputs)
        predictions = torch.softmax(outputs.logits, dim=1)
        predicted_class = torch.argmax(predictions, dim=1)
    
    # Sonuçları hazırla
    predicted_label = label_encoder.inverse_transform(predicted_class.numpy())[0]
    confidence = predictions[0][predicted_class].item() * 100
    
    return predicted_label, confidence

def main():
    try:
        print("Model yükleniyor...")
        model, tokenizer, label_encoder = load_model()
        
        print("\nModel hazır! Test cümleleri girmeye başlayabilirsiniz.")
        print("Çıkmak için 'q' yazın.\n")
        
        while True:
            text = input("\nTest edilecek metin: ")
            if text.lower() == 'q':
                break
            
            predicted_label, confidence = predict_text(text, model, tokenizer, label_encoder)
            print(f"\nSonuç:")
            print(f"Tahmin: {predicted_label}")
            print(f"Güven: %{confidence:.2f}")
            
    except Exception as e:
        print(f"\nHata oluştu: {str(e)}")
        print("Lütfen model dosyalarının doğru konumda olduğundan emin olun.")

if __name__ == "__main__":
    main() 
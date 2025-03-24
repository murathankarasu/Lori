import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import pickle
import os

class HateSpeechModel:
    def __init__(self):
        self.model_path = "model"
        self.model = AutoModelForSequenceClassification.from_pretrained(self.model_path)
        self.tokenizer = AutoTokenizer.from_pretrained(self.model_path)
        
        # Label encoder'ı yükle
        label_encoder_path = os.path.join(self.model_path, "label_encoder.pkl")
        with open(label_encoder_path, "rb") as f:
            self.label_encoder = pickle.load(f)
    
    def predict(self, text: str):
        # Metni tokenize et
        inputs = self.tokenizer(text, truncation=True, padding=True, max_length=128, return_tensors="pt")
        
        # Tahmin yap
        self.model.eval()
        with torch.no_grad():
            outputs = self.model(**inputs)
            predictions = torch.softmax(outputs.logits, dim=1)
            predicted_class = torch.argmax(predictions, dim=1)
        
        # Sonuçları hazırla
        predicted_label = self.label_encoder.inverse_transform(predicted_class.cpu().numpy())[0]
        confidence = float(predictions[0][predicted_class].item())
        
        return {
            "is_hate_speech": bool(predicted_label == "nefret"),
            "confidence": confidence,
            "category": str(predicted_label)
        } 
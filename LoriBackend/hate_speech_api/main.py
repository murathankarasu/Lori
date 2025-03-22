from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import pickle
import os
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="Nefret Söylemi Tespit API",
    description="Metinlerde nefret söylemi tespiti yapan API",
    version="1.0.0"
)

# CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Tüm originlere izin ver (production'da değiştirilmeli)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request modeli
class TextRequest(BaseModel):
    text: str

# Response modeli
class PredictionResponse(BaseModel):
    text: str
    is_hate_speech: bool
    confidence: float
    label: str

# Global değişkenler
model = None
tokenizer = None
label_encoder = None

def load_model():
    global model, tokenizer, label_encoder
    
    try:
        print("Model yükleniyor...")
        model_path = "model"
        
        # Model ve tokenizer'ı yükle
        model = AutoModelForSequenceClassification.from_pretrained(model_path)
        tokenizer = AutoTokenizer.from_pretrained(model_path)
        
        # Label encoder'ı yükle
        with open(os.path.join(model_path, "label_encoder.pkl"), "rb") as f:
            label_encoder = pickle.load(f)
        
        # Model'i eval moduna al
        model.eval()
        print("Model başarıyla yüklendi!")
        
    except Exception as e:
        print(f"Model yüklenirken hata oluştu: {str(e)}")
        raise e

@app.on_event("startup")
async def startup_event():
    load_model()

def predict_text(text: str):
    # Metni tokenize et
    inputs = tokenizer(text, truncation=True, padding=True, max_length=128, return_tensors="pt")
    
    # Tahmin yap
    with torch.no_grad():
        outputs = model(**inputs)
        predictions = torch.softmax(outputs.logits, dim=1)
        predicted_class = torch.argmax(predictions, dim=1)
    
    # Sonuçları hazırla
    predicted_label = label_encoder.inverse_transform(predicted_class.numpy())[0]
    confidence = predictions[0][predicted_class].item() * 100
    
    return predicted_label, confidence

@app.get("/")
async def root():
    return {
        "message": "Nefret Söylemi Tespit API'sine Hoş Geldiniz",
        "status": "active",
        "endpoints": {
            "/predict": "POST - Metin analizi yapar"
        }
    }

@app.post("/predict", response_model=PredictionResponse)
async def analyze_text(request: TextRequest):
    try:
        if not request.text.strip():
            raise HTTPException(status_code=400, detail="Metin boş olamaz")
        
        # Tahmin yap
        label, confidence = predict_text(request.text)
        
        return PredictionResponse(
            text=request.text,
            is_hate_speech=(label == 1),
            confidence=confidence,
            label="Nefret Söylemi" if label == 1 else "Normal Metin"
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 
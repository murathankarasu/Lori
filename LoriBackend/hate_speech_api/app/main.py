from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from .model_handler import HateSpeechModel
import uvicorn

app = FastAPI(title="Nefret Söylemi Tespit API")
model = HateSpeechModel()

class TextRequest(BaseModel):
    text: str

class PredictionResponse(BaseModel):
    is_hate_speech: bool
    confidence: float
    category: str

@app.post("/api/check-hate-speech", response_model=PredictionResponse)
async def check_hate_speech(request: TextRequest):
    try:
        result = model.predict(request.text)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000) 
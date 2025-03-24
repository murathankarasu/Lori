from flask import Flask, request, jsonify
from flask_cors import CORS
from model_handler import HateSpeechModel
import numpy as np

app = Flask(__name__)
CORS(app)

# Model'i global olarak yükle
model = HateSpeechModel()

@app.route('/api/check-hate-speech', methods=['GET', 'POST'])
def analyze_text():
    try:
        if request.method == 'GET':
            # GET isteği için test yanıtı
            return jsonify({
                "is_hate_speech": False,
                "confidence": 0.95,
                "category": "normal"
            })
            
        # POST isteği için
        data = request.get_json()
        if not data or 'text' not in data:
            return jsonify({"error": "Metin sağlanmadı"}), 400
            
        result = model.predict(data['text'])
        return jsonify(result)
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True) 
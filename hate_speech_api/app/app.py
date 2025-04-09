from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
from datetime import datetime
import os
import traceback
from model_handler import ModelHandler

# Loglama ayarları
logging.basicConfig(
    level=logging.DEBUG,  # DEBUG seviyesine çektik
    format='[%(asctime)s] %(levelname)s: %(message)s',
    handlers=[
        logging.FileHandler('logs/api.log'),
        logging.StreamHandler()  # Konsola da log çıktısı ekledik
    ]
)

logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Model'i global olarak yükle
try:
    model = ModelHandler()
    logger.info("Model başarıyla yüklendi")
except Exception as e:
    logger.error(f"Model yüklenirken hata oluştu: {str(e)}")
    logger.error(f"Stack trace: {traceback.format_exc()}")
    raise

@app.route('/api/check-hate-speech', methods=['GET', 'POST'])
def analyze_text():
    try:
        if request.method == 'GET':
            return jsonify({
                "status": "success",
                "message": "API çalışıyor",
                "timestamp": datetime.now().isoformat()
            })

        data = request.get_json()
        if not data or 'text' not in data:
            logger.warning("Metin parametresi eksik")
            return jsonify({
                "status": "error",
                "message": "Metin sağlanmadı",
                "timestamp": datetime.now().isoformat()
            }), 400

        logger.debug(f"Analiz edilecek metin: {data['text']}")
        
        # Metin analizi
        result = model.analyze_text(data['text'])
        logger.debug(f"Analiz sonucu: {result}")
        
        # Yanıt formatı
        response = {
            "status": "success",
            "data": {
                "is_hate_speech": result["is_hate_speech"],
                "confidence": result["confidence"],
                "category": result["category"],
                "details": result["details"]
            },
            "timestamp": datetime.now().isoformat()
        }
        
        logger.info(f"Metin analizi başarılı: {response}")
        return jsonify(response)

    except Exception as e:
        error_msg = f"Hata oluştu: {str(e)}\nStack trace: {traceback.format_exc()}"
        logger.error(error_msg)
        error_response = {
            "status": "error",
            "message": str(e),
            "timestamp": datetime.now().isoformat()
        }
        return jsonify(error_response), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat()
    })

@app.route('/api/categories', methods=['GET'])
def get_categories():
    try:
        categories = model.categories
        return jsonify({
            "status": "success",
            "data": categories,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        error_msg = f"Kategoriler alınırken hata oluştu: {str(e)}\nStack trace: {traceback.format_exc()}"
        logger.error(error_msg)
        return jsonify({
            "status": "error",
            "message": str(e),
            "timestamp": datetime.now().isoformat()
        }), 500

if __name__ == '__main__':
    # Logs klasörünü oluştur
    os.makedirs('logs', exist_ok=True)
    app.run(host='0.0.0.0', port=8000, debug=True)
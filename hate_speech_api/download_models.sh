#!/bin/bash

# Gerekli klasörleri oluştur
echo "📁 Klasörler oluşturuluyor..."
mkdir -p model
mkdir -p logs

# Model dosyalarını Google Drive'dan indir
echo "📥 Model dosyaları Google Drive'dan indiriliyor..."

# Her bir dosyayı ayrı ayrı indir
gdown "1PHig41O8g3ocLlgrPCno8-65P4-vbbKM/config.json" -O model/config.json
gdown "1PHig41O8g3ocLlgrPCno8-65P4-vbbKM/label_encoder.pkl" -O model/label_encoder.pkl
gdown "1PHig41O8g3ocLlgrPCno8-65P4-vbbKM/model.safetensors" -O model/model.safetensors
gdown "1PHig41O8g3ocLlgrPCno8-65P4-vbbKM/special_tokens_map.json" -O model/special_tokens_map.json
gdown "1PHig41O8g3ocLlgrPCno8-65P4-vbbKM/tokenizer_config.json" -O model/tokenizer_config.json
gdown "1PHig41O8g3ocLlgrPCno8-65P4-vbbKM/tokenizer.json" -O model/tokenizer.json
gdown "1PHig41O8g3ocLlgrPCno8-65P4-vbbKM/vocab.txt" -O model/vocab.txt

# Model dosyalarının varlığını kontrol et
echo "✅ Model dosyaları kontrol ediliyor..."
ls -la model/

# API'yi başlat
echo "🚀 API başlatılıyor..."
PORT=10000 python app/app.py 
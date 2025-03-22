import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report
import pickle
import re
import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize

class HateSpeechModel:
    def __init__(self):
        self.vectorizer = None
        self.model = None
        self.stop_words = set(stopwords.words('turkish'))
        self.initialize_model()
    
    def initialize_model(self):
        try:
            # Model ve vectorizer'ı yükle
            with open('models/vectorizer.pkl', 'rb') as f:
                self.vectorizer = pickle.load(f)
            with open('models/model.pkl', 'rb') as f:
                self.model = pickle.load(f)
        except FileNotFoundError:
            print("Model dosyaları bulunamadı. Model eğitilecek.")
            self.train_model()
    
    def preprocess_text(self, text):
        # Küçük harfe çevir
        text = text.lower()
        # Özel karakterleri temizle
        text = re.sub(r'[^\w\s]', '', text)
        # Türkçe karakterleri normalize et
        text = text.replace('ı', 'i').replace('ğ', 'g').replace('ü', 'u').replace('ş', 's').replace('ö', 'o').replace('ç', 'c')
        # Stop words'leri temizle
        words = word_tokenize(text)
        text = ' '.join([word for word in words if word not in self.stop_words])
        return text
    
    def train_model(self):
        # Veriyi yükle
        data = pd.read_csv('data/HateSpeechDatasetBalanced.csv')
        
        # Veriyi preprocess et
        data['processed_text'] = data['text'].apply(self.preprocess_text)
        
        # Veriyi böl
        X_train, X_test, y_train, y_test = train_test_split(
            data['processed_text'], 
            data['label'], 
            test_size=0.2, 
            random_state=42
        )
        
        # Vectorizer'ı oluştur ve eğit
        self.vectorizer = TfidfVectorizer(max_features=5000)
        X_train_vectorized = self.vectorizer.fit_transform(X_train)
        
        # Modeli eğit
        self.model = LogisticRegression(max_iter=1000)
        self.model.fit(X_train_vectorized, y_train)
        
        # Modeli değerlendir
        X_test_vectorized = self.vectorizer.transform(X_test)
        y_pred = self.model.predict(X_test_vectorized)
        print(classification_report(y_test, y_pred))
        
        # Model ve vectorizer'ı kaydet
        with open('models/vectorizer.pkl', 'wb') as f:
            pickle.dump(self.vectorizer, f)
        with open('models/model.pkl', 'wb') as f:
            pickle.dump(self.model, f)
    
    def predict(self, text):
        # Metni preprocess et
        processed_text = self.preprocess_text(text)
        
        # Vectorize et
        text_vectorized = self.vectorizer.transform([processed_text])
        
        # Tahmin yap
        prediction = self.model.predict(text_vectorized)[0]
        confidence = np.max(self.model.predict_proba(text_vectorized))
        
        return {
            "is_hate_speech": bool(prediction),
            "confidence": float(confidence),
            "category": "nefret" if prediction else "temiz"
        } 
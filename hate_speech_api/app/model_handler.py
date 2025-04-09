import logging
import os
import numpy as np
import torch
import pickle
import re
from typing import Dict, List, Tuple
from transformers import AutoTokenizer, AutoModelForSequenceClassification

logger = logging.getLogger(__name__)

class ModelHandler:
    def __init__(self):
        self.model_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'model'))
        self.tokenizer = None
        self.model = None
        self.label_encoder = None
        self.categories = {
            "hate": [
                "racist", "xenophobic", "antisemitic", "islamophobic",
                "homophobic", "transphobic", "misogynistic", "ableist",
                "religious_hate", "ethnic_hate", "political_hate"
            ],
            "violence": [
                "physical_threat", "verbal_threat", "intimidation",
                "harassment", "bullying", "cyberbullying", "stalking",
                "terrorism", "incitement_to_violence"
            ],
            "sexual": [
                "sexual_harassment", "sexual_assault", "sexual_exploitation",
                "child_sexual_abuse", "revenge_porn", "sexual_blackmail",
                "sexual_cyberbullying", "sexual_grooming"
            ],
            "other": [
                "profanity", "insult", "defamation", "slander",
                "libel", "hate_symbols", "conspiracy_theories",
                "fake_news", "disinformation", "misinformation"
            ]
        }
        self.emoji_pattern = re.compile("["
            u"\U0001F600-\U0001F64F"  # emojis
            u"\U0001F300-\U0001F5FF"  # symbols & pictographs
            u"\U0001F680-\U0001F6FF"  # transport & map symbols
            u"\U0001F1E0-\U0001F1FF"  # flags (iOS)
            u"\U00002702-\U000027B0"
            u"\U000024C2-\U0001F251"
            "]+", flags=re.UNICODE)
        self._load_model()
        
    def _load_model(self):
        try:
            logger.info(f"Model yolu: {self.model_path}")
            if not os.path.exists(self.model_path):
                raise FileNotFoundError(f"Model klasörü bulunamadı: {self.model_path}")
                
            # Model ve tokenizer'ı yükle
            logger.info("Model ve tokenizer yükleniyor...")
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_path, local_files_only=True)
            self.model = AutoModelForSequenceClassification.from_pretrained(self.model_path, local_files_only=True)
            logger.info("Model ve tokenizer başarıyla yüklendi")
            
            # Label encoder'ı yükle
            label_encoder_path = os.path.join(self.model_path, 'label_encoder.pkl')
            if os.path.exists(label_encoder_path):
                logger.info("Label encoder yükleniyor...")
                with open(label_encoder_path, 'rb') as f:
                    self.label_encoder = pickle.load(f)
                logger.info("Label encoder başarıyla yüklendi")
            else:
                logger.warning("Label encoder bulunamadı, varsayılan kategoriler kullanılacak")
                self.label_encoder = None
                
        except Exception as e:
            logger.error(f"Model yüklenirken hata oluştu: {str(e)}")
            raise
            
    def get_categories(self):
        if self.label_encoder:
            return list(self.label_encoder.classes_)
        return ["nefret_söylemi_değil", "nefret_söylemi"]
            
    def analyze_text(self, text: str) -> Dict:
        try:
            logger.debug(f"Metin analiz ediliyor: {text}")
            
            # Tokenize input
            inputs = self.tokenizer(text, return_tensors="pt", truncation=True, max_length=512)
            logger.debug("Metin tokenize edildi")
            
            # Get model predictions
            with torch.no_grad():
                outputs = self.model(**inputs)
                logits = outputs.logits
                probabilities = torch.softmax(logits, dim=1)
                logger.debug("Model tahmini yapıldı")
                
            # Get predicted class and confidence
            predicted_class = torch.argmax(probabilities, dim=1).item()
            confidence = float(probabilities[0][predicted_class].item())
            logger.debug(f"Tahmin edilen sınıf: {predicted_class}, Güven: {confidence}")
            
            # Get category
            if self.label_encoder:
                category = str(self.label_encoder.inverse_transform([predicted_class])[0])
            else:
                category = "nefret_söylemi" if predicted_class == 1 else "nefret_söylemi_değil"
            logger.debug(f"Kategori: {category}")
            
            # Detailed analysis
            details = self._get_detailed_analysis(text, category, confidence)
            logger.debug(f"Detaylı analiz: {details}")
            
            return {
                "is_hate_speech": bool(category == "nefret_söylemi"),
                "confidence": confidence,
                "category": category,
                "details": details
            }
            
        except Exception as e:
            logger.error(f"Tahmin yapılırken hata oluştu: {str(e)}")
            raise
            
    def _get_detailed_analysis(self, text: str, category: str, confidence: float) -> Dict:
        try:
            # Calculate emoji count
            emoji_count = int(len(self.emoji_pattern.findall(text)))
            
            # Text length
            text_length = int(len(text))
            
            # Category details
            category_details = self._get_category_details(category)
            
            # Risk level
            severity_score = int(self._calculate_severity_score(confidence, category_details))
            
            # Found sensitive words
            found_words = self._find_sensitive_words(text)
            
            # Additional metrics
            metrics = self._calculate_additional_metrics(text)
            
            return {
                "emoji_count": emoji_count,
                "text_length": text_length,
                "category_details": category_details,
                "severity_score": severity_score,
                "found_words": found_words,
                "metrics": metrics
            }
        except Exception as e:
            logger.error(f"Detaylı analiz yapılırken hata oluştu: {str(e)}")
            raise
    
    def _get_category_details(self, category: str) -> List[str]:
        return self.categories.get(category, [])
    
    def _calculate_severity_score(self, confidence: float, category_details: List[str]) -> int:
        base_score = int(confidence * 100)
        category_multiplier = len(category_details) * 0.2
        return min(100, int(base_score * (1 + category_multiplier)))
    
    def _find_sensitive_words(self, text: str) -> List[str]:
        sensitive_words = []
        text_lower = text.lower()
        
        for category, words in self.categories.items():
            for word in words:
                if word in text_lower:
                    sensitive_words.append(word)
        
        return sensitive_words
    
    def _calculate_additional_metrics(self, text: str) -> Dict:
        try:
            # Calculate word count
            word_count = int(len(text.split()))
            
            # Calculate average word length
            words = text.split()
            avg_word_length = float(sum(len(word) for word in words) / len(words) if words else 0)
            
            # Calculate punctuation count
            punctuation_count = int(sum(1 for char in text if char in '.,!?;:'))
            
            # Calculate capitalization ratio
            capital_ratio = float(sum(1 for char in text if char.isupper()) / len(text) if text else 0)
            
            return {
                "word_count": word_count,
                "average_word_length": round(avg_word_length, 2),
                "punctuation_count": punctuation_count,
                "capitalization_ratio": round(capital_ratio, 2)
            }
        except Exception as e:
            logger.error(f"Metrikler hesaplanırken hata oluştu: {str(e)}")
            raise
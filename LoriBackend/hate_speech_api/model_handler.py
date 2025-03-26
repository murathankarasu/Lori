import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import pickle
import os
import re
from typing import Dict, List, Tuple
import numpy as np


class HateSpeechModel:
    def __init__(self):
        self.model_path = "model"
        self.model = AutoModelForSequenceClassification.from_pretrained(self.model_path)
        self.tokenizer = AutoTokenizer.from_pretrained(self.model_path)

        # Label encoder'ı yükle
        label_encoder_path = os.path.join(self.model_path, "label_encoder.pkl")
        with open(label_encoder_path, "rb") as f:
            self.label_encoder = pickle.load(f)
            
        # Hate speech categories with detailed subcategories
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
        
        # Emoji regex pattern
        self.emoji_pattern = re.compile("["
            u"\U0001F600-\U0001F64F"  # emojis
            u"\U0001F300-\U0001F5FF"  # symbols & pictographs
            u"\U0001F680-\U0001F6FF"  # transport & map symbols
            u"\U0001F1E0-\U0001F1FF"  # flags (iOS)
            u"\U00002702-\U000027B0"
            u"\U000024C2-\U0001F251"
            "]+", flags=re.UNICODE)

    def analyze_text(self, text: str) -> Dict:
        # Tokenize text
        inputs = self.tokenizer(text, truncation=True, padding=True, max_length=128, return_tensors="pt")

        # Make prediction
        self.model.eval()
        with torch.no_grad():
            outputs = self.model(**inputs)
            predictions = torch.softmax(outputs.logits, dim=1)
            predicted_class = torch.argmax(predictions, dim=1)

        # Prepare results
        predicted_label = self.label_encoder.inverse_transform(predicted_class.cpu().numpy())[0]
        confidence = float(predictions[0][predicted_class].item())
        
        # Detailed analysis
        details = self._get_detailed_analysis(text, predicted_label, confidence)
        
        return {
            "is_hate_speech": bool(predicted_label == "hate"),
            "confidence": confidence,
            "category": str(predicted_label),
            "details": details
        }
    
    def _get_detailed_analysis(self, text: str, category: str, confidence: float) -> Dict:
        # Calculate emoji count
        emoji_count = len(self.emoji_pattern.findall(text))
        
        # Text length
        text_length = len(text)
        
        # Category details
        category_details = self._get_category_details(category)
        
        # Risk level
        severity_score = self._calculate_severity_score(confidence, category_details)
        
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
        # Calculate word count
        word_count = len(text.split())
        
        # Calculate average word length
        words = text.split()
        avg_word_length = sum(len(word) for word in words) / len(words) if words else 0
        
        # Calculate punctuation count
        punctuation_count = sum(1 for char in text if char in '.,!?;:')
        
        # Calculate capitalization ratio
        capital_ratio = sum(1 for char in text if char.isupper()) / len(text) if text else 0
        
        return {
            "word_count": word_count,
            "average_word_length": round(avg_word_length, 2),
            "punctuation_count": punctuation_count,
            "capitalization_ratio": round(capital_ratio, 2)
        }
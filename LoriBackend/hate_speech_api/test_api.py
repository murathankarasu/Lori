import requests
import json
from datetime import datetime
import time
import logging
from typing import List, Dict
import os
import re

# Configure logging
logging.basicConfig(
    filename='logs/test_api.log',
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s'
)

class HateSpeechAPITester:
    def __init__(self):
        self.base_url = "http://localhost:8000/api"
        self.test_cases = self._load_test_cases()
        
    def _load_test_cases(self) -> List[Dict]:
        return [
            # Nefret Söylemi Test Senaryoları
            {
                "category": "hate",
                "description": "Irkçı içerik",
                "text": "All people from that race are inferior and should be eliminated!",
                "expected_categories": ["racist", "ethnic_hate"]
            },
            {
                "category": "hate",
                "description": "Homofobik içerik",
                "text": "These people are disgusting and should be punished for their lifestyle!",
                "expected_categories": ["homophobic"]
            },
            {
                "category": "hate",
                "description": "Dini nefret",
                "text": "Followers of this religion are terrorists and should be banned!",
                "expected_categories": ["religious_hate"]
            },
            {
                "category": "hate",
                "description": "Cinsiyetçi nefret",
                "text": "Women should stay in the kitchen and not try to be leaders!",
                "expected_categories": ["misogynistic"]
            },
            {
                "category": "hate",
                "description": "Engelli düşmanlığı",
                "text": "These disabled people are a burden to society!",
                "expected_categories": ["ableist"]
            },
            
            # Şiddet Test Senaryoları
            {
                "category": "violence",
                "description": "Fiziksel tehdit",
                "text": "I will beat you up and make you regret your actions!",
                "expected_categories": ["physical_threat", "intimidation"]
            },
            {
                "category": "violence",
                "description": "Siber zorbalık",
                "text": "You're worthless and should kill yourself! Nobody likes you!",
                "expected_categories": ["cyberbullying", "verbal_threat"]
            },
            {
                "category": "violence",
                "description": "Terörizm",
                "text": "We should bomb their buildings and make them pay!",
                "expected_categories": ["terrorism", "incitement_to_violence"]
            },
            {
                "category": "violence",
                "description": "Taciz",
                "text": "I'll keep messaging you until you respond, you can't ignore me forever!",
                "expected_categories": ["harassment", "stalking"]
            },
            {
                "category": "violence",
                "description": "Şiddet teşviki",
                "text": "Everyone should attack these people and teach them a lesson!",
                "expected_categories": ["incitement_to_violence"]
            },
            
            # Cinsel İçerik Test Senaryoları
            {
                "category": "sexual",
                "description": "Cinsel taciz",
                "text": "Send me your nudes or I'll spread rumors about you!",
                "expected_categories": ["sexual_harassment", "sexual_blackmail"]
            },
            {
                "category": "sexual",
                "description": "İntikam pornosu tehdidi",
                "text": "I'll share your private photos if you don't do what I say!",
                "expected_categories": ["revenge_porn", "sexual_cyberbullying"]
            },
            {
                "category": "sexual",
                "description": "Cinsel sömürü",
                "text": "I'll help you get famous if you send me those photos!",
                "expected_categories": ["sexual_exploitation"]
            },
            {
                "category": "sexual",
                "description": "Çocuk istismarı",
                "text": "This content is not appropriate for children!",
                "expected_categories": ["child_sexual_abuse"]
            },
            
            # Diğer Kategoriler Test Senaryoları
            {
                "category": "other",
                "description": "Komplo teorileri",
                "text": "The government is controlling our minds with 5G!",
                "expected_categories": ["conspiracy_theories", "misinformation"]
            },
            {
                "category": "other",
                "description": "Sahte haber",
                "text": "Breaking: Aliens have taken over the government!",
                "expected_categories": ["fake_news", "disinformation"]
            },
            {
                "category": "other",
                "description": "Küfür",
                "text": "You're a complete idiot and should go to hell!",
                "expected_categories": ["profanity", "insult"]
            },
            {
                "category": "other",
                "description": "İftira",
                "text": "This person is a criminal and should be arrested immediately!",
                "expected_categories": ["defamation", "slander"]
            },
            
            # Güvenli İçerik Test Senaryoları
            {
                "category": "safe",
                "description": "Pozitif içerik",
                "text": "Thank you for your help! You're amazing!",
                "expected_categories": []
            },
            {
                "category": "safe",
                "description": "Nötr içerik",
                "text": "The weather is nice today.",
                "expected_categories": []
            },
            {
                "category": "safe",
                "description": "Eğitim içeriği",
                "text": "Let's learn about mathematics and science!",
                "expected_categories": []
            },
            {
                "category": "safe",
                "description": "Spor içeriği",
                "text": "The team played well in the match today!",
                "expected_categories": []
            },
            {
                "category": "safe",
                "description": "Teknoloji içeriği",
                "text": "The new smartphone has amazing features!",
                "expected_categories": []
            }
        ]
    
    def test_health_check(self) -> bool:
        """Test the health check endpoint"""
        try:
            response = requests.get(f"{self.base_url}/health")
            if response.status_code == 200:
                logging.info("Health check successful")
                return True
            else:
                logging.error(f"Health check failed with status code: {response.status_code}")
                return False
        except Exception as e:
            logging.error(f"Health check error: {str(e)}")
            return False
    
    def test_get_categories(self) -> bool:
        """Test the categories endpoint"""
        try:
            response = requests.get(f"{self.base_url}/categories")
            if response.status_code == 200:
                data = response.json()
                if data["status"] == "success" and "data" in data:
                    logging.info("Categories retrieved successfully")
                    return True
            logging.error(f"Categories endpoint failed with status code: {response.status_code}")
            return False
        except Exception as e:
            logging.error(f"Categories endpoint error: {str(e)}")
            return False
    
    def analyze_text(self, text: str) -> Dict:
        """Analyze text using the API"""
        try:
            response = requests.post(
                f"{self.base_url}/check-hate-speech",
                json={"text": text}
            )
            
            if response.status_code == 200:
                data = response.json()
                if data["status"] == "success":
                    return data["data"]
            return None
        except Exception as e:
            logging.error(f"Analysis error: {str(e)}")
            return None
    
    def run_interactive_test(self):
        """Run interactive test mode"""
        print("\n=== Nefret Söylemi Analiz Sistemi ===")
        print("Komutlar:")
        print("- Metin girin: Analiz için metin girin")
        print("- 'q': Çıkış")
        print("- 't': Test senaryolarını çalıştır")
        print("- 'h': Yardım menüsü")
        print("- 'c': Kategorileri göster")
        print("- 's': Sonuçları kaydet")
        print("\nÖrnek cümleler:")
        print("1. 'Seni öldüreceğim ve pişman olacaksın!'")
        print("2. 'Bu insanlar toplum için bir yük!'")
        print("3. 'Hava bugün çok güzel!'")
        print("4. 'Bana fotoğraf göndermezsen seninle ilgili yalan haberler yayacağım!'")
        print("5. 'Bu insanlar terörist ve yasaklanmalılar!'\n")
        
        while True:
            text = input("\nAnaliz edilecek metni girin: ").strip()
            
            if text.lower() == 'q':
                print("\nProgram sonlandırılıyor...")
                break
            elif text.lower() == 't':
                self.run_test_cases()
                continue
            elif text.lower() == 'h':
                print("\nKomutlar:")
                print("- Metin girin: Analiz için metin girin")
                print("- 'q': Çıkış")
                print("- 't': Test senaryolarını çalıştır")
                print("- 'h': Yardım menüsü")
                print("- 'c': Kategorileri göster")
                print("- 's': Sonuçları kaydet")
                continue
            elif text.lower() == 'c':
                print("\nKategoriler:")
                print("1. Nefret Söylemi:")
                print("   - Irkçılık")
                print("   - Homofobi")
                print("   - Dini nefret")
                print("   - Cinsiyetçilik")
                print("   - Engelli düşmanlığı")
                print("\n2. Şiddet:")
                print("   - Fiziksel tehdit")
                print("   - Siber zorbalık")
                print("   - Terörizm")
                print("   - Taciz")
                print("   - Şiddet teşviki")
                print("\n3. Cinsel İçerik:")
                print("   - Cinsel taciz")
                print("   - İntikam pornosu")
                print("   - Cinsel sömürü")
                print("   - Çocuk istismarı")
                print("\n4. Diğer:")
                print("   - Komplo teorileri")
                print("   - Sahte haber")
                print("   - Küfür")
                print("   - İftira")
                continue
            elif text.lower() == 's':
                self.save_results()
                continue
            
            if not text:
                print("Lütfen bir metin girin!")
                continue
            
            result = self.analyze_text(text)
            self.print_analysis_result(result)
    
    def run_test_cases(self):
        """Run predefined test cases"""
        print("\n=== Running Test Cases ===")
        for test_case in self.test_cases:
            print(f"\nTest: {test_case['description']}")
            print(f"Text: {test_case['text']}")
            result = self.analyze_text(test_case['text'])
            self.print_analysis_result(result)
    
    def run_all_tests(self):
        """Run all tests and print results"""
        print("\n=== Hate Speech API Test Suite ===")
        print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        # Test health check
        print("Testing health check endpoint...")
        if self.test_health_check():
            print("✓ Health check successful")
        else:
            print("✗ Health check failed")
        
        # Test categories endpoint
        print("\nTesting categories endpoint...")
        if self.test_get_categories():
            print("✓ Categories endpoint successful")
        else:
            print("✗ Categories endpoint failed")
        
        # Run interactive test
        self.run_interactive_test()

    def save_results(self):
        """Save analysis results to a file"""
        try:
            filename = f"analysis_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(self.results, f, ensure_ascii=False, indent=2)
            print(f"\nSonuçlar {filename} dosyasına kaydedildi.")
        except Exception as e:
            print(f"Sonuçlar kaydedilirken hata oluştu: {str(e)}")
    
    def print_analysis_result(self, result: Dict):
        """Print analysis result in a formatted way"""
        if not result:
            print("\n❌ Hata: Metin analiz edilemedi")
            return
            
        print("\n=== Nefret Söylemi Analiz Sonucu ===")
        print(f"Zaman: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        print("\nTahmin:")
        print(f"Kategori: {result['category']}")
        print(f"Güven Skoru: {result['confidence']*100:.2f}%")
        print(f"Nefret Söylemi mi?: {'Evet' if result['is_hate_speech'] else 'Hayır'}")
        
        print("\nDetaylar:")
        details = result['details']
        print(f"Emoji Sayısı: {details['emoji_count']}")
        print(f"Metin Uzunluğu: {details['text_length']} karakter")
        print(f"Kategori Detayları: {', '.join(details['category_details'])}")
        print(f"Ciddiyet Skoru: {details['severity_score']}")
        
        print("\nMetrikler:")
        metrics = details['metrics']
        print(f"Kelime Sayısı: {metrics['word_count']}")
        print(f"Ortalama Kelime Uzunluğu: {metrics['average_word_length']}")
        print(f"Noktalama Sayısı: {metrics['punctuation_count']}")
        print(f"Büyük Harf Oranı: {metrics['capitalization_ratio']:.2%}")
        
        print("\nRisk Seviyesi:")
        if result['confidence'] > 0.8:
            print("⚠️ YÜKSEK RİSK")
        elif result['confidence'] > 0.5:
            print("⚠️ ORTA RİSK")
        elif result['confidence'] > 0.3:
            print("⚠️ DÜŞÜK RİSK")
        else:
            print("✅ GÜVENLİ")

if __name__ == "__main__":
    # Create logs directory if it doesn't exist
    os.makedirs('logs', exist_ok=True)
    
    # Run tests
    tester = HateSpeechAPITester()
    tester.run_all_tests()
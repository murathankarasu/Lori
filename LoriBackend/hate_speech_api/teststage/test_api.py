import requests
import json

def test_hate_speech_api():
    # API endpoint
    url = "http://localhost:8000/api/check-hate-speech"
    
    # Test metinleri
    test_texts = [
        "Bu çok güzel bir gün!",
        "Seni seviyorum.",
        "Bu insanlar çok kötü, hepsi ölmeli!",
        "Harika bir iş yapıyorsun.",
        "Seni öldüreceğim, piç kurusu!"
    ]
    
    # Her test metni için API'yi çağır
    for text in test_texts:
        print(f"\nTest metni: {text}")
        try:
            response = requests.post(url, json={"text": text})
            if response.status_code == 200:
                result = response.json()
                print(f"Sonuç: {json.dumps(result, indent=2, ensure_ascii=False)}")
            else:
                print(f"Hata: {response.status_code}")
                print(response.text)
        except Exception as e:
            print(f"Hata oluştu: {str(e)}")

if __name__ == "__main__":
    test_hate_speech_api() 
import requests
import json

def test_sentence(sentence):
    try:
        # API'ye istek gönder
        response = requests.post(
            "http://localhost:8000/api/check-hate-speech",
            json={"text": sentence}
        )
        
        if response.status_code == 200:
            result = response.json()
            print("\n📝 Cümle:", sentence)
            print("📊 Sonuç:")
            print(f"  - Kategori: {result['data']['category']}")
            print(f"  - Nefret Söylemi mi?: {'Evet' if result['data']['is_hate_speech'] else 'Hayır'}")
            print(f"  - Güven Skoru: {result['data']['confidence']:.2%}")
        else:
            print(f"❌ Hata: {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"❌ Hata oluştu: {str(e)}")

if __name__ == "__main__":
    print("🚀 Nefret Söylemi Analiz Aracı")
    print("=" * 50)
    
    while True:
        print("\n1️⃣ Yeni cümle analiz et")
        print("2️⃣ Çıkış")
        
        choice = input("\nSeçiminiz (1/2): ")
        
        if choice == "1":
            sentence = input("\nAnaliz edilecek cümleyi girin: ")
            test_sentence(sentence)
        elif choice == "2":
            print("\n👋 Program sonlandırılıyor...")
            break
        else:
            print("\n❌ Geçersiz seçim!") 
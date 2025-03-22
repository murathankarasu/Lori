from transformers import AutoTokenizer, AutoModelForSequenceClassification
import os

def download_model():
    print("Model indirme işlemi başlıyor...")
    model_name = "bert-base-uncased"
    
    # Model ve tokenizer'ı indir
    print("Tokenizer indiriliyor...")
    tokenizer = AutoTokenizer.from_pretrained(model_name, local_files_only=False)
    print("Model indiriliyor...")
    model = AutoModelForSequenceClassification.from_pretrained(model_name, local_files_only=False)
    
    # Modeli kaydet
    model_save_path = "pretrained_model"
    if not os.path.exists(model_save_path):
        os.makedirs(model_save_path)
    
    print("Model ve tokenizer kaydediliyor...")
    model.save_pretrained(model_save_path)
    tokenizer.save_pretrained(model_save_path)
    print("İndirme işlemi tamamlandı!")

if __name__ == "__main__":
    download_model() 
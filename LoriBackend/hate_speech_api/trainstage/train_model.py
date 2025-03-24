import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch
from sklearn.preprocessing import LabelEncoder
import os
from torch.utils.data import DataLoader
from torch.optim import AdamW
from tqdm import tqdm

def load_data(dataset_path):
    # Veri setini yükle
    df = pd.read_csv(dataset_path)
    return df

def prepare_dataset(texts, labels, tokenizer):
    # Metinleri tokenize et
    encodings = tokenizer(texts.tolist(), truncation=True, padding=True, max_length=128, return_tensors="pt")
    
    # Dataset sınıfı
    class HateSpeechDataset(torch.utils.data.Dataset):
        def __init__(self, encodings, labels):
            self.encodings = encodings
            self.labels = torch.tensor(labels)

        def __getitem__(self, idx):
            item = {key: val[idx] for key, val in self.encodings.items()}
            item['labels'] = self.labels[idx]
            return item

        def __len__(self):
            return len(self.labels)

    return HateSpeechDataset(encodings, labels)

def train_model():
    # Veri setini yükle
    dataset_path = "dataset/HateSpeechDatasetMedium.csv"  # Orta boyutlu veri setini kullan
    print("Veri seti yükleniyor...")
    df = load_data(dataset_path)
    print(f"Toplam örnek sayısı: {len(df)}")
    
    # Etiketleri sayısal değerlere dönüştür
    label_encoder = LabelEncoder()
    labels = label_encoder.fit_transform(df['Label'])
    
    # Veriyi eğitim ve test setlerine ayır
    train_texts, val_texts, train_labels, val_labels = train_test_split(
        df['Content'], labels, test_size=0.2, random_state=42
    )
    print(f"Eğitim seti boyutu: {len(train_texts)}")
    print(f"Validasyon seti boyutu: {len(val_texts)}")
    
    # Model ve tokenizer'ı yükle
    print("\nModel yükleniyor...")
    model_name = "distilbert-base-uncased"  # Daha küçük model
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForSequenceClassification.from_pretrained(
        model_name, num_labels=len(label_encoder.classes_)
    )
    
    # Dataset'leri hazırla
    print("Veri setleri hazırlanıyor...")
    train_dataset = prepare_dataset(train_texts, train_labels, tokenizer)
    val_dataset = prepare_dataset(val_texts, val_labels, tokenizer)
    
    # DataLoader'ları oluştur
    batch_size = 64  # Batch size'ı artırdık
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=batch_size)
    
    # Eğitim parametrelerini ayarla
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Kullanılan cihaz: {device}")
    model.to(device)
    
    optimizer = AdamW(model.parameters(), lr=2e-5)
    num_epochs = 3
    
    # Eğitim döngüsü
    print("\nEğitim başlıyor...")
    for epoch in range(num_epochs):
        model.train()
        total_loss = 0
        progress_bar = tqdm(train_loader, desc=f'Epoch {epoch + 1}/{num_epochs}')
        
        for batch in progress_bar:
            optimizer.zero_grad()
            
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            labels = batch['labels'].to(device)
            
            outputs = model(input_ids=input_ids, attention_mask=attention_mask, labels=labels)
            loss = outputs.loss
            
            loss.backward()
            optimizer.step()
            
            total_loss += loss.item()
            progress_bar.set_postfix({'loss': total_loss / len(train_loader)})
        
        # Validasyon
        model.eval()
        val_loss = 0
        correct = 0
        total = 0
        
        print("\nValidasyon yapılıyor...")
        with torch.no_grad():
            for batch in val_loader:
                input_ids = batch['input_ids'].to(device)
                attention_mask = batch['attention_mask'].to(device)
                labels = batch['labels'].to(device)
                
                outputs = model(input_ids=input_ids, attention_mask=attention_mask, labels=labels)
                val_loss += outputs.loss.item()
                
                predictions = torch.argmax(outputs.logits, dim=1)
                correct += (predictions == labels).sum().item()
                total += labels.size(0)
        
        val_accuracy = correct / total
        print(f'Epoch {epoch + 1}: Validation Loss = {val_loss / len(val_loader):.4f}, Accuracy = {val_accuracy:.4f}')
    
    # Modeli kaydet
    print("\nModel kaydediliyor...")
    model_save_path = "model"
    if not os.path.exists(model_save_path):
        os.makedirs(model_save_path)
    
    model.save_pretrained(model_save_path)
    tokenizer.save_pretrained(model_save_path)
    
    # Label encoder'ı kaydet
    import pickle
    with open(os.path.join(model_save_path, "label_encoder.pkl"), "wb") as f:
        pickle.dump(label_encoder, f)
    
    print("Eğitim tamamlandı!")

if __name__ == "__main__":
    train_model() 
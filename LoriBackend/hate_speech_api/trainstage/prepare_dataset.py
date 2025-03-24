import pandas as pd
import numpy as np

# Orijinal veri setini oku
print("Veri seti okunuyor...")
df = pd.read_csv("dataset/HateSpeechDatasetBalanced.csv")

# Veri setinin boyutunu göster
print(f"Orijinal veri seti boyutu: {len(df)} satır")

# Her sınıftan 5000'er örnek al (toplam 10,000 örnek)
sample_size = 5000
print(f"\nHer sınıftan {sample_size} örnek alınıyor...")

# Sınıflara göre örnekleme yap
df_sampled = pd.DataFrame()
for label in df['Label'].unique():
    temp_df = df[df['Label'] == label].sample(n=sample_size, random_state=42)
    df_sampled = pd.concat([df_sampled, temp_df])

# Veriyi karıştır
df_sampled = df_sampled.sample(frac=1, random_state=42).reset_index(drop=True)

# Yeni veri setini kaydet
output_file = "dataset/HateSpeechDatasetMedium.csv"
df_sampled.to_csv(output_file, index=False)
print(f"\nOrta boyutlu veri seti kaydedildi: {output_file}")
print(f"Yeni veri seti boyutu: {len(df_sampled)} satır") 
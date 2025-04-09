import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import pickle
import os
import json
from datetime import datetime
import re

def load_model():
    # Load model and tokenizer
    model_path = "model"
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model directory not found: {model_path}")
        
    model = AutoModelForSequenceClassification.from_pretrained(model_path)
    tokenizer = AutoTokenizer.from_pretrained(model_path)
    
    # Load label encoder
    label_encoder_path = os.path.join(model_path, "label_encoder.pkl")
    if not os.path.exists(label_encoder_path):
        raise FileNotFoundError(f"Label encoder file not found: {label_encoder_path}")
        
    with open(label_encoder_path, "rb") as f:
        label_encoder = pickle.load(f)
    
    return model, tokenizer, label_encoder

def analyze_text(text, model, tokenizer, label_encoder):
    # Tokenize text
    inputs = tokenizer(text, truncation=True, padding=True, max_length=128, return_tensors="pt")
    
    # Make prediction
    model.eval()
    with torch.no_grad():
        outputs = model(**inputs)
        predictions = torch.softmax(outputs.logits, dim=1)
        predicted_class = torch.argmax(predictions, dim=1)
    
    # Prepare results
    predicted_label = label_encoder.inverse_transform(predicted_class.numpy())[0]
    confidence = predictions[0][predicted_class].item()
    
    # Calculate additional metrics
    metrics = calculate_metrics(text)
    
    return {
        "predicted_label": predicted_label,
        "confidence": confidence,
        "is_hate_speech": bool(predicted_label == "hate"),
        "metrics": metrics,
        "timestamp": datetime.now().isoformat()
    }

def calculate_metrics(text):
    # Calculate word count
    word_count = len(text.split())
    
    # Calculate average word length
    words = text.split()
    avg_word_length = sum(len(word) for word in words) / len(words) if words else 0
    
    # Calculate punctuation count
    punctuation_count = sum(1 for char in text if char in '.,!?;:')
    
    # Calculate capitalization ratio
    capital_ratio = sum(1 for char in text if char.isupper()) / len(text) if text else 0
    
    # Calculate emoji count
    emoji_pattern = re.compile("["
        u"\U0001F600-\U0001F64F"  # emojis
        u"\U0001F300-\U0001F5FF"  # symbols & pictographs
        u"\U0001F680-\U0001F6FF"  # transport & map symbols
        u"\U0001F1E0-\U0001F1FF"  # flags (iOS)
        u"\U00002702-\U000027B0"
        u"\U000024C2-\U0001F251"
        "]+", flags=re.UNICODE)
    emoji_count = len(emoji_pattern.findall(text))
    
    return {
        "word_count": word_count,
        "average_word_length": round(avg_word_length, 2),
        "punctuation_count": punctuation_count,
        "capitalization_ratio": round(capital_ratio, 2),
        "emoji_count": emoji_count
    }

def print_analysis_result(result):
    print("\n=== Hate Speech Analysis Result ===")
    print(f"Timestamp: {result['timestamp']}")
    print("\nPrediction:")
    print(f"Category: {result['predicted_label']}")
    print(f"Confidence: {result['confidence']*100:.2f}%")
    print(f"Is Hate Speech: {'Yes' if result['is_hate_speech'] else 'No'}")
    
    print("\nMetrics:")
    metrics = result['metrics']
    print(f"Word Count: {metrics['word_count']}")
    print(f"Average Word Length: {metrics['average_word_length']}")
    print(f"Punctuation Count: {metrics['punctuation_count']}")
    print(f"Capitalization Ratio: {metrics['capitalization_ratio']:.2%}")
    print(f"Emoji Count: {metrics['emoji_count']}")
    
    print("\nRisk Level:")
    if result['confidence'] > 0.8:
        print("⚠️ HIGH RISK")
    elif result['confidence'] > 0.5:
        print("⚠️ MEDIUM RISK")
    elif result['confidence'] > 0.3:
        print("⚠️ LOW RISK")
    else:
        print("✅ SAFE")

def main():
    try:
        print("Loading model...")
        model, tokenizer, label_encoder = load_model()
        
        print("\nModel is ready! Enter text to analyze.")
        print("Type 'q' to quit.")
        print("Type 's' to save results to file.\n")
        
        while True:
            text = input("\nEnter text to analyze: ")
            
            if text.lower() == 'q':
                break
            elif text.lower() == 's':
                save_results()
                continue
            
            if not text.strip():
                print("Please enter some text!")
                continue
            
            result = analyze_text(text, model, tokenizer, label_encoder)
            print_analysis_result(result)
            
    except Exception as e:
        print(f"\nError occurred: {str(e)}")
        print("Please make sure model files are in the correct location.")

def save_results():
    try:
        filename = f"analysis_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
        print(f"\nResults saved to {filename}")
    except Exception as e:
        print(f"Error saving results: {str(e)}")

if __name__ == "__main__":
    main() 
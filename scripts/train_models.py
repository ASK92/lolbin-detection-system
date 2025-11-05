import argparse
import pandas as pd
import numpy as np
from pathlib import Path
import joblib
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
from app.ml.feature_extraction import FeatureExtractor
from app.ml.random_forest_model import RandomForestDetector
from app.ml.lstm_model import LSTMDetector
from app.core.config import settings
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def load_data(data_path: str) -> tuple:
    """Load and preprocess training data."""
    logger.info(f"Loading data from {data_path}")
    
    # Load CSV or JSON
    if data_path.endswith('.csv'):
        df = pd.read_csv(data_path)
    elif data_path.endswith('.json'):
        df = pd.read_json(data_path)
    else:
        raise ValueError("Unsupported file format. Use CSV or JSON.")
    
    logger.info(f"Loaded {len(df)} records")
    
    # Extract features
    feature_extractor = FeatureExtractor()
    feature_names = feature_extractor.get_feature_names()
    
    X = []
    y = []
    
    for _, row in df.iterrows():
        event_data = {
            'command_line': row.get('command_line', ''),
            'process_name': row.get('process_name', ''),
            'parent_image': row.get('parent_image', ''),
            'user': row.get('user', ''),
            'integrity_level': row.get('integrity_level', ''),
            'timestamp': row.get('timestamp')
        }
        
        features = feature_extractor.extract_features(event_data)
        feature_vector = [features.get(name, 0.0) for name in feature_names]
        X.append(feature_vector)
        
        # Label: 0 for benign, 1 for malicious
        label = row.get('label', row.get('is_malicious', 0))
        if isinstance(label, bool):
            label = 1 if label else 0
        y.append(label)
    
    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.float32)
    
    logger.info(f"Feature matrix shape: {X.shape}")
    logger.info(f"Labels: {sum(y)} malicious, {len(y) - sum(y)} benign")
    
    return X, y, feature_names


def train_random_forest(X_train, y_train, X_test, y_test, feature_names, output_path: str):
    """Train Random Forest model."""
    logger.info("Training Random Forest model...")
    
    rf_detector = RandomForestDetector()
    rf_detector.train(
        X_train, y_train, feature_names,
        n_estimators=100,
        max_depth=20,
        min_samples_split=5,
        random_state=42
    )
    
    # Evaluate
    y_pred = rf_detector.model.predict(X_test)
    y_pred_proba = rf_detector.model.predict_proba(X_test)[:, 1]
    
    accuracy = accuracy_score(y_test, y_pred)
    logger.info(f"Random Forest Accuracy: {accuracy:.4f}")
    logger.info("\nClassification Report:")
    logger.info(classification_report(y_test, y_pred))
    logger.info("\nConfusion Matrix:")
    logger.info(confusion_matrix(y_test, y_pred))
    
    # Save model
    rf_detector.save_model(output_path)
    logger.info(f"Random Forest model saved to {output_path}")


def train_lstm(X_train, y_train, X_test, y_test, feature_names, output_path: str):
    """Train LSTM model."""
    import torch
    logger.info("Training LSTM model...")
    
    lstm_detector = LSTMDetector()
    lstm_detector.train(
        X_train, y_train, feature_names,
        hidden_size=128,
        num_layers=2,
        dropout=0.2,
        learning_rate=0.001,
        epochs=50,
        batch_size=32
    )
    
    # Evaluate
    X_test_tensor = torch.FloatTensor(X_test).unsqueeze(1).to(lstm_detector.device)
    with torch.no_grad():
        y_pred_proba = lstm_detector.model(X_test_tensor).cpu().numpy().flatten()
        y_pred = (y_pred_proba > 0.5).astype(int)
    
    accuracy = accuracy_score(y_test, y_pred)
    logger.info(f"LSTM Accuracy: {accuracy:.4f}")
    logger.info("\nClassification Report:")
    logger.info(classification_report(y_test, y_pred))
    logger.info("\nConfusion Matrix:")
    logger.info(confusion_matrix(y_test, y_pred))
    
    # Save model
    lstm_detector.save_model(output_path)
    logger.info(f"LSTM model saved to {output_path}")


def main():
    parser = argparse.ArgumentParser(description='Train ML models for LOLBin detection')
    parser.add_argument('--data-path', type=str, required=True, help='Path to training data (CSV or JSON)')
    parser.add_argument('--test-size', type=float, default=0.2, help='Test set size ratio')
    parser.add_argument('--random-forest', action='store_true', help='Train Random Forest model')
    parser.add_argument('--lstm', action='store_true', help='Train LSTM model')
    parser.add_argument('--rf-output', type=str, help='Output path for Random Forest model')
    parser.add_argument('--lstm-output', type=str, help='Output path for LSTM model')
    
    args = parser.parse_args()
    
    # Load data
    X, y, feature_names = load_data(args.data_path)
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=args.test_size, random_state=42, stratify=y
    )
    
    logger.info(f"Training set: {len(X_train)} samples")
    logger.info(f"Test set: {len(X_test)} samples")
    
    # Train models
    if args.random_forest or (not args.lstm):
        rf_output = args.rf_output or settings.random_forest_model_path
        train_random_forest(X_train, y_train, X_test, y_test, feature_names, rf_output)
    
    if args.lstm:
        import torch
        lstm_output = args.lstm_output or settings.lstm_model_path
        train_lstm(X_train, y_train, X_test, y_test, feature_names, lstm_output)
    
    logger.info("Training complete!")


if __name__ == "__main__":
    main()


#!/usr/bin/env python3
"""
Train models with sample weights to handle duplicates
"""

import argparse
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import joblib
from pathlib import Path
import sys

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.ml.feature_extraction import FeatureExtractor

def load_data_with_weights(data_path: str):
    """Load data and extract features with weights."""
    print(f"Loading data from {data_path}...")
    df = pd.read_csv(data_path)
    print(f"  Loaded {len(df):,} records")
    
    # Check if weight column exists
    if 'weight' in df.columns:
        weights = df['weight'].values
        print(f"  Using sample weights (range: {weights.min():.4f} to {weights.max():.4f})")
    else:
        # Create weights based on duplicates
        print("  No weight column found, creating weights from duplicates...")
        occurrence_count = df.groupby(['process_name', 'command_line'])['process_name'].transform('count')
        weights = 1.0 / occurrence_count
        weights = weights / weights.max()  # Normalize
        print(f"  Created weights (range: {weights.min():.4f} to {weights.max():.4f})")
    
    # Extract features
    feature_extractor = FeatureExtractor()
    feature_names = feature_extractor.get_feature_names()
    
    X = []
    y = []
    sample_weights = []
    
    for idx, row in df.iterrows():
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
        
        label = row.get('label', 0)
        if isinstance(label, bool):
            label = 1 if label else 0
        y.append(label)
        
        sample_weights.append(weights[idx])
    
    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.float32)
    sample_weights = np.array(sample_weights, dtype=np.float32)
    
    print(f"  Feature matrix shape: {X.shape}")
    print(f"  Labels: {sum(y)} malicious, {len(y) - sum(y)} benign")
    
    return X, y, sample_weights, feature_names

def train_with_weights(X_train, y_train, X_test, y_test, sample_weights_train, feature_names, output_path: str):
    """Train Random Forest with sample weights."""
    print("\nTraining Random Forest with sample weights...")
    
    model = RandomForestClassifier(
        n_estimators=100,
        max_depth=20,
        min_samples_split=5,
        random_state=42,
        n_jobs=-1,
        class_weight='balanced'  # Also handle class imbalance
    )
    
    # Train with sample weights
    model.fit(X_train, y_train, sample_weight=sample_weights_train)
    
    # Evaluate
    y_pred = model.predict(X_test)
    y_pred_proba = model.predict_proba(X_test)[:, 1]
    
    accuracy = accuracy_score(y_test, y_pred)
    print(f"\nAccuracy: {accuracy:.4f}")
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred))
    print("\nConfusion Matrix:")
    print(confusion_matrix(y_test, y_pred))
    
    # Feature importance
    print("\nTop 10 Most Important Features:")
    feature_importance = list(zip(feature_names, model.feature_importances_))
    feature_importance.sort(key=lambda x: x[1], reverse=True)
    for name, importance in feature_importance[:10]:
        print(f"  {name:30s} {importance:.4f}")
    
    # Save model
    model_data = {
        'model': model,
        'feature_names': feature_names
    }
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(model_data, output_path)
    print(f"\nModel saved to {output_path}")

def main():
    parser = argparse.ArgumentParser(description='Train model with sample weights')
    parser.add_argument('--data-path', type=str, required=True, help='Path to training data CSV')
    parser.add_argument('--test-size', type=float, default=0.2, help='Test set size ratio')
    parser.add_argument('--output', type=str, default='models/random_forest_weighted.pkl', 
                       help='Output path for model')
    
    args = parser.parse_args()
    
    # Load data
    X, y, sample_weights, feature_names = load_data_with_weights(args.data_path)
    
    # Split data
    X_train, X_test, y_train, y_test, weights_train, weights_test = train_test_split(
        X, y, sample_weights, test_size=args.test_size, random_state=42, stratify=y
    )
    
    print(f"\nTraining set: {len(X_train)} samples")
    print(f"Test set: {len(X_test)} samples")
    
    # Train
    train_with_weights(X_train, y_train, X_test, y_test, weights_train, feature_names, args.output)
    
    print("\nTraining complete!")

if __name__ == "__main__":
    main()


import joblib
import numpy as np
from typing import Dict, Any, List
from pathlib import Path
from sklearn.ensemble import RandomForestClassifier
from app.ml.feature_extraction import FeatureExtractor


class RandomForestDetector:
    """Random Forest model for LOLBin detection."""
    
    def __init__(self, model_path: str = None):
        self.model_path = model_path
        self.model = None
        self.feature_extractor = FeatureExtractor()
        self.feature_names = None
        self.is_loaded = False
    
    def load_model(self, model_path: str = None):
        """Load trained Random Forest model."""
        if model_path:
            self.model_path = model_path
        
        if not self.model_path or not Path(self.model_path).exists():
            raise FileNotFoundError(f"Model file not found: {self.model_path}")
        
        model_data = joblib.load(self.model_path)
        
        if isinstance(model_data, dict):
            self.model = model_data.get('model')
            self.feature_names = model_data.get('feature_names')
        else:
            self.model = model_data
            self.feature_names = self.feature_extractor.get_feature_names()
        
        self.is_loaded = True
    
    def predict(self, event_data: Dict[str, Any]) -> Dict[str, Any]:
        """Predict malicious score for event."""
        if not self.is_loaded:
            raise ValueError("Model not loaded. Call load_model() first.")
        
        # Extract features
        features = self.feature_extractor.extract_features(event_data)
        
        # Convert to feature vector in correct order
        feature_vector = np.array([features.get(name, 0.0) for name in self.feature_names]).reshape(1, -1)
        
        # Predict
        probability = self.model.predict_proba(feature_vector)[0]
        malicious_score = float(probability[1])  # Probability of malicious class
        
        return {
            'score': malicious_score,
            'features': features,
            'feature_vector': feature_vector.tolist()[0]
        }
    
    def train(self, X: np.ndarray, y: np.ndarray, feature_names: List[str], **kwargs):
        """Train Random Forest model."""
        n_estimators = kwargs.get('n_estimators', 100)
        max_depth = kwargs.get('max_depth', None)
        min_samples_split = kwargs.get('min_samples_split', 2)
        min_samples_leaf = kwargs.get('min_samples_leaf', 1)
        random_state = kwargs.get('random_state', 42)
        
        self.model = RandomForestClassifier(
            n_estimators=n_estimators,
            max_depth=max_depth,
            min_samples_split=min_samples_split,
            min_samples_leaf=min_samples_leaf,
            random_state=random_state,
            n_jobs=-1
        )
        
        self.model.fit(X, y)
        self.feature_names = feature_names
        self.is_loaded = True
    
    def save_model(self, model_path: str):
        """Save trained model."""
        if not self.model:
            raise ValueError("No model to save. Train model first.")
        
        model_data = {
            'model': self.model,
            'feature_names': self.feature_names
        }
        
        Path(model_path).parent.mkdir(parents=True, exist_ok=True)
        joblib.dump(model_data, model_path)
        self.model_path = model_path




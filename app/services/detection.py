from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from app.models.database import Event, Detection
from app.ml.random_forest_model import RandomForestDetector
from app.ml.lstm_model import LSTMDetector
from app.ml.feature_extraction import FeatureExtractor
from app.core.config import settings
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class DetectionService:
    """Service for detecting malicious events using ML models."""
    
    def __init__(self):
        self.rf_detector = None
        self.lstm_detector = None
        self.feature_extractor = FeatureExtractor()
        self._load_models()
    
    def _load_models(self):
        """Load ML models."""
        try:
            self.rf_detector = RandomForestDetector()
            self.rf_detector.load_model(settings.random_forest_model_path)
            logger.info("Random Forest model loaded successfully")
        except Exception as e:
            logger.warning(f"Failed to load Random Forest model: {e}")
        
        try:
            self.lstm_detector = LSTMDetector()
            self.lstm_detector.load_model(settings.lstm_model_path)
            logger.info("LSTM model loaded successfully")
        except Exception as e:
            logger.warning(f"Failed to load LSTM model: {e}")
    
    def detect(self, db: Session, event_data: Dict[str, Any]) -> Detection:
        """Detect malicious activity in event and store results."""
        # Store event in database
        event = Event(
            event_id=event_data.get('event_id', ''),
            timestamp=event_data.get('timestamp', datetime.now()),
            process_name=event_data.get('process_name', ''),
            command_line=event_data.get('command_line', ''),
            parent_image=event_data.get('parent_image'),
            user=event_data.get('user'),
            integrity_level=event_data.get('integrity_level'),
            raw_event_data=event_data.get('raw_event_data')
        )
        db.add(event)
        db.commit()
        db.refresh(event)
        
        # Extract features
        features = self.feature_extractor.extract_features(event_data)
        
        # Run ML models
        rf_score = 0.0
        lstm_score = 0.0
        
        if self.rf_detector:
            try:
                rf_result = self.rf_detector.predict(event_data)
                rf_score = rf_result['score']
            except Exception as e:
                logger.error(f"Random Forest prediction error: {e}")
        
        if self.lstm_detector:
            try:
                lstm_result = self.lstm_detector.predict(event_data)
                lstm_score = lstm_result['score']
            except Exception as e:
                logger.error(f"LSTM prediction error: {e}")
        
        # Combine scores (weighted average)
        if rf_score > 0 and lstm_score > 0:
            malicious_score = (rf_score * 0.6) + (lstm_score * 0.4)
        elif rf_score > 0:
            malicious_score = rf_score
        elif lstm_score > 0:
            malicious_score = lstm_score
        else:
            # Fallback: use feature-based heuristic
            malicious_score = self._heuristic_score(features)
        
        # Determine if malicious
        is_malicious = malicious_score >= settings.detection_threshold
        
        # Create detection record
        detection = Detection(
            event_id=event.id,
            malicious_score=malicious_score,
            random_forest_score=rf_score,
            lstm_score=lstm_score,
            is_malicious=is_malicious,
            features=features
        )
        
        db.add(detection)
        db.commit()
        db.refresh(detection)
        
        logger.info(f"Detection created: ID={detection.id}, Score={malicious_score:.4f}, Malicious={is_malicious}")
        
        return detection
    
    def _heuristic_score(self, features: Dict[str, float]) -> float:
        """Calculate heuristic score based on features when models unavailable."""
        score = 0.0
        
        # Process-based indicators
        if features.get('is_lolbin_process', 0) > 0:
            score += 0.2
        if features.get('is_powershell', 0) > 0:
            score += 0.1
        if features.get('parent_is_lolbin', 0) > 0:
            score += 0.15
        
        # Command-based indicators
        suspicious_count = features.get('suspicious_pattern_count', 0)
        score += min(suspicious_count * 0.15, 0.4)
        
        if features.get('has_encoded_command', 0) > 0:
            score += 0.2
        if features.get('has_network_activity', 0) > 0:
            score += 0.15
        
        # Entropy-based indicators
        if features.get('has_high_entropy', 0) > 0:
            score += 0.1
        
        return min(score, 1.0)
    
    def get_detection(self, db: Session, detection_id: int) -> Optional[Detection]:
        """Get detection by ID."""
        return db.query(Detection).filter(Detection.id == detection_id).first()
    
    def list_detections(
        self,
        db: Session,
        skip: int = 0,
        limit: int = 100,
        malicious_only: bool = False
    ):
        """List detections with pagination."""
        query = db.query(Detection)
        
        if malicious_only:
            query = query.filter(Detection.is_malicious == True)
        
        return query.order_by(Detection.timestamp.desc()).offset(skip).limit(limit).all()





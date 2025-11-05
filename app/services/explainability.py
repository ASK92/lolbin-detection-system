import shap
import numpy as np
from typing import Dict, Any, Optional
from lime import lime_tabular
from openai import OpenAI
from app.core.config import settings
from app.ml.feature_extraction import FeatureExtractor
from app.ml.random_forest_model import RandomForestDetector
import logging

logger = logging.getLogger(__name__)


class ExplainabilityService:
    """Service for generating explanations using SHAP, LIME, and OpenAI."""
    
    def __init__(self):
        self.feature_extractor = FeatureExtractor()
        self.rf_detector = None
        self.openai_client = None
        self._initialize()
    
    def _initialize(self):
        """Initialize explainability components."""
        try:
            self.rf_detector = RandomForestDetector()
            self.rf_detector.load_model(settings.random_forest_model_path)
        except Exception as e:
            logger.warning(f"Failed to load RF model for explainability: {e}")
        
        if settings.openai_api_key and settings.openai_api_key != "sk-test-key-please-replace":
            try:
                self.openai_client = OpenAI(api_key=settings.openai_api_key)
            except TypeError as e:
                # Handle OpenAI client version compatibility
                try:
                    from openai import OpenAI
                    self.openai_client = OpenAI(api_key=settings.openai_api_key)
                except Exception as e2:
                    logger.warning(f"Failed to initialize OpenAI client: {e2}")
            except Exception as e:
                logger.warning(f"Failed to initialize OpenAI client: {e}")
    
    def generate_shap_explanation(
        self,
        event_data: Dict[str, Any],
        background_data: Optional[np.ndarray] = None
    ) -> Dict[str, Any]:
        """Generate SHAP explanation for event."""
        if not self.rf_detector:
            return {"error": "Random Forest model not available for SHAP"}
        
        try:
            # Extract features
            features = self.feature_extractor.extract_features(event_data)
            feature_vector = np.array([features.get(name, 0.0) for name in self.rf_detector.feature_names]).reshape(1, -1)
            
            # Use TreeExplainer for Random Forest
            explainer = shap.TreeExplainer(self.rf_detector.model)
            
            # Generate SHAP values
            shap_values = explainer.shap_values(feature_vector)
            
            # Handle binary classification output
            if isinstance(shap_values, list):
                shap_values = shap_values[1]  # Get values for positive class
            
            shap_values = shap_values[0]  # Get first (and only) sample
            
            # Create feature importance mapping
            feature_importance = {}
            for i, feature_name in enumerate(self.rf_detector.feature_names):
                feature_importance[feature_name] = float(shap_values[i])
            
            # Get top contributing features
            sorted_features = sorted(
                feature_importance.items(),
                key=lambda x: abs(x[1]),
                reverse=True
            )
            
            top_features = {
                'positive': [f for f, v in sorted_features[:10] if v > 0],
                'negative': [f for f, v in sorted_features[:10] if v < 0]
            }
            
            return {
                'shap_values': feature_importance,
                'top_features': top_features,
                'base_value': float(explainer.expected_value[1] if isinstance(explainer.expected_value, np.ndarray) else explainer.expected_value)
            }
        except Exception as e:
            logger.error(f"SHAP explanation error: {e}")
            return {"error": str(e)}
    
    def generate_lime_explanation(
        self,
        event_data: Dict[str, Any],
        training_data: Optional[np.ndarray] = None
    ) -> Dict[str, Any]:
        """Generate LIME explanation for event."""
        if not self.rf_detector:
            return {"error": "Random Forest model not available for LIME"}
        
        try:
            # Extract features
            features = self.feature_extractor.extract_features(event_data)
            feature_vector = np.array([features.get(name, 0.0) for name in self.rf_detector.feature_names]).reshape(1, -1)
            
            # Create dummy training data if not provided
            if training_data is None:
                # Generate random background data
                training_data = np.random.rand(100, len(self.rf_detector.feature_names))
            
            # Create LIME explainer
            explainer = lime_tabular.LimeTabularExplainer(
                training_data,
                feature_names=self.rf_detector.feature_names,
                mode='classification'
            )
            
            # Define prediction function
            def predict_fn(X):
                return self.rf_detector.model.predict_proba(X)
            
            # Generate explanation
            explanation = explainer.explain_instance(
                feature_vector[0],
                predict_fn,
                num_features=20
            )
            
            # Extract explanation data
            explanation_data = {}
            for feature, weight in explanation.as_list():
                explanation_data[feature] = float(weight)
            
            return {
                'lime_explanation': explanation_data,
                'prediction': float(explanation.predict_proba[1])
            }
        except Exception as e:
            logger.error(f"LIME explanation error: {e}")
            return {"error": str(e)}
    
    def generate_openai_explanation(
        self,
        event_data: Dict[str, Any],
        features: Dict[str, float],
        shap_values: Optional[Dict[str, float]] = None,
        malicious_score: float = 0.0
    ) -> str:
        """Generate natural language explanation using OpenAI."""
        if not self.openai_client:
            # Fallback explanation when OpenAI is not available
            command_line = event_data.get('command_line', 'N/A')
            process_name = event_data.get('process_name', 'N/A')
            return f"Analysis for {process_name}: Command '{command_line[:100]}...' scored {malicious_score:.4f}. This is a test explanation as OpenAI API is not configured. Please configure OPENAI_API_KEY in .env for full explanations."
        
        try:
            # Prepare prompt
            command_line = event_data.get('command_line', 'N/A')
            process_name = event_data.get('process_name', 'N/A')
            
            # Get top contributing features
            top_features_text = ""
            if shap_values:
                sorted_shap = sorted(shap_values.items(), key=lambda x: abs(x[1]), reverse=True)[:10]
                top_features_text = "\n".join([f"- {feat}: {val:.4f}" for feat, val in sorted_shap])
            
            prompt = f"""Analyze this Windows security event and provide a clear explanation of why it was flagged as potentially malicious.

Event Details:
- Process: {process_name}
- Command Line: {command_line}
- Malicious Score: {malicious_score:.4f}

Key Features Contributing to Detection:
{top_features_text if top_features_text else "Feature analysis not available"}

Provide a professional security analyst explanation covering:
1. What the command/process is doing
2. Why it was flagged (suspicious indicators)
3. Risk assessment (Low/Medium/High)
4. Recommended investigation steps

Keep the explanation concise, technical but accessible, and focused on actionable insights."""

            response = self.openai_client.chat.completions.create(
                model=settings.openai_model,
                messages=[
                    {"role": "system", "content": "You are a cybersecurity analyst expert at detecting and explaining living-off-the-land (LOLBin) attacks. Provide clear, professional analysis."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,
                max_tokens=500
            )
            
            return response.choices[0].message.content
        except Exception as e:
            logger.error(f"OpenAI explanation error: {e}")
            return f"Error generating explanation: {str(e)}"
    
    def generate_all_explanations(
        self,
        event_data: Dict[str, Any],
        features: Dict[str, float],
        malicious_score: float,
        background_data: Optional[np.ndarray] = None
    ) -> Dict[str, Any]:
        """Generate all types of explanations."""
        results = {}
        
        # SHAP
        shap_result = self.generate_shap_explanation(event_data, background_data)
        results['shap'] = shap_result
        
        # LIME
        lime_result = self.generate_lime_explanation(event_data)
        results['lime'] = lime_result
        
        # OpenAI
        shap_values = shap_result.get('shap_values') if 'shap_values' in shap_result else None
        openai_explanation = self.generate_openai_explanation(
            event_data,
            features,
            shap_values,
            malicious_score
        )
        results['openai'] = openai_explanation
        
        return results


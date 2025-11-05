from pydantic_settings import BaseSettings
from typing import Optional
import os


class Settings(BaseSettings):
    # Database
    database_url: str = "sqlite:///./lolbin_detection.db"
    
    # OpenAI
    openai_api_key: Optional[str] = None
    openai_model: str = "gpt-4-turbo-preview"
    
    # Alerting
    slack_webhook_url: Optional[str] = None
    email_smtp_host: Optional[str] = None
    email_smtp_port: int = 587
    email_from: Optional[str] = None
    email_to: Optional[str] = None
    email_username: Optional[str] = None
    email_password: Optional[str] = None
    
    # Detection Thresholds
    detection_threshold: float = 0.7
    alert_threshold: float = 0.9
    
    # Model Paths
    random_forest_model_path: str = "data/models/random_forest_model.pkl"
    lstm_model_path: str = "data/models/lstm_model.pth"
    
    # API
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    api_reload: bool = True
    
    # Logging
    log_level: str = "INFO"
    log_file: str = "logs/app.log"
    
    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()


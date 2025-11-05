from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime


class EventCreate(BaseModel):
    event_id: str
    timestamp: datetime
    process_name: str
    command_line: str
    parent_image: Optional[str] = None
    user: Optional[str] = None
    integrity_level: Optional[str] = None
    raw_event_data: Optional[Dict[str, Any]] = None


class EventResponse(BaseModel):
    id: int
    event_id: str
    timestamp: datetime
    process_name: str
    command_line: str
    parent_image: Optional[str]
    user: Optional[str]
    integrity_level: Optional[str]
    raw_event_data: Optional[Dict[str, Any]]
    created_at: datetime
    
    class Config:
        from_attributes = True


class DetectionCreate(BaseModel):
    event_id: int
    malicious_score: float
    random_forest_score: float
    lstm_score: float
    is_malicious: bool
    features: Dict[str, Any]
    shap_values: Optional[Dict[str, Any]] = None
    lime_explanation: Optional[Dict[str, Any]] = None
    openai_explanation: Optional[str] = None


class DetectionResponse(BaseModel):
    id: int
    event_id: int
    timestamp: datetime
    malicious_score: float
    random_forest_score: float
    lstm_score: float
    is_malicious: bool
    features: Dict[str, Any]
    shap_values: Optional[Dict[str, Any]]
    lime_explanation: Optional[Dict[str, Any]]
    openai_explanation: Optional[str]
    analyst_feedback: Optional[str]
    analyst_notes: Optional[str]
    feedback_timestamp: Optional[datetime]
    created_at: datetime
    event: Optional[EventResponse] = None
    
    class Config:
        from_attributes = True


class FeedbackCreate(BaseModel):
    detection_id: int
    feedback: str = Field(..., pattern="^(true_positive|false_positive|true_negative|false_negative)$")
    notes: Optional[str] = None


class FeedbackResponse(BaseModel):
    id: int
    detection_id: int
    feedback: str
    notes: Optional[str]
    timestamp: datetime
    
    class Config:
        from_attributes = True


class StatsResponse(BaseModel):
    total_events: int
    total_detections: int
    malicious_detections: int
    false_positives: int
    false_negatives: int
    detection_rate: float
    false_positive_rate: float
    recent_detections: list




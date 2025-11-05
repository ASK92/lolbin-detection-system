from sqlalchemy import Column, Integer, String, Float, Text, DateTime, Boolean, JSON
from sqlalchemy.sql import func
from app.core.database import Base


class Event(Base):
    __tablename__ = "events"
    
    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(String, index=True)
    timestamp = Column(DateTime, default=func.now(), index=True)
    process_name = Column(String, index=True)
    command_line = Column(Text)
    parent_image = Column(String)
    user = Column(String)
    integrity_level = Column(String)
    raw_event_data = Column(JSON)
    created_at = Column(DateTime, default=func.now())


class Detection(Base):
    __tablename__ = "detections"
    
    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, index=True)
    timestamp = Column(DateTime, default=func.now(), index=True)
    malicious_score = Column(Float, index=True)
    random_forest_score = Column(Float)
    lstm_score = Column(Float)
    is_malicious = Column(Boolean, default=False, index=True)
    features = Column(JSON)
    shap_values = Column(JSON)
    lime_explanation = Column(JSON)
    openai_explanation = Column(Text)
    analyst_feedback = Column(String)
    analyst_notes = Column(Text)
    feedback_timestamp = Column(DateTime)
    created_at = Column(DateTime, default=func.now())


class SystemStats(Base):
    __tablename__ = "system_stats"
    
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=func.now(), index=True)
    total_events = Column(Integer)
    total_detections = Column(Integer)
    malicious_detections = Column(Integer)
    false_positives = Column(Integer)
    false_negatives = Column(Integer)
    stats_data = Column(JSON)





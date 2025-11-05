from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.core.database import get_db
from app.models import schemas
from app.services.detection import DetectionService
from app.services.explainability import ExplainabilityService
from app.services.alerting import AlertingService

router = APIRouter()
detection_service = DetectionService()
explainability_service = ExplainabilityService()
alerting_service = AlertingService()


@router.post("/events", response_model=schemas.DetectionResponse)
async def create_detection(
    event: schemas.EventCreate,
    db: Session = Depends(get_db)
):
    """Submit event for detection and analysis."""
    try:
        event_data = event.dict()
        detection = detection_service.detect(db, event_data)
        
        # Generate explanations
        explanations = explainability_service.generate_all_explanations(
            event_data,
            detection.features,
            detection.malicious_score
        )
        
        # Update detection with explanations
        if 'shap' in explanations and 'shap_values' in explanations['shap']:
            detection.shap_values = explanations['shap']['shap_values']
        
        if 'lime' in explanations and 'lime_explanation' in explanations['lime']:
            detection.lime_explanation = explanations['lime']['lime_explanation']
        
        if 'openai' in explanations:
            detection.openai_explanation = explanations['openai']
        
        db.commit()
        db.refresh(detection)
        
        # Send alert if threshold exceeded
        if detection.is_malicious:
            alerting_service.send_alert(
                schemas.DetectionResponse.from_orm(detection),
                event_data
            )
        
        return detection
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/detections", response_model=List[schemas.DetectionResponse])
async def list_detections(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    malicious_only: bool = Query(False),
    db: Session = Depends(get_db)
):
    """List detections with pagination."""
    detections = detection_service.list_detections(
        db,
        skip=skip,
        limit=limit,
        malicious_only=malicious_only
    )
    return detections


@router.get("/detections/{detection_id}", response_model=schemas.DetectionResponse)
async def get_detection(
    detection_id: int,
    db: Session = Depends(get_db)
):
    """Get detection by ID with full details."""
    detection = detection_service.get_detection(db, detection_id)
    if not detection:
        raise HTTPException(status_code=404, detail="Detection not found")
    return detection


@router.post("/feedback", response_model=schemas.FeedbackResponse)
async def submit_feedback(
    feedback: schemas.FeedbackCreate,
    db: Session = Depends(get_db)
):
    """Submit analyst feedback on detection."""
    detection = detection_service.get_detection(db, feedback.detection_id)
    if not detection:
        raise HTTPException(status_code=404, detail="Detection not found")
    
    detection.analyst_feedback = feedback.feedback
    detection.analyst_notes = feedback.notes
    from datetime import datetime
    detection.feedback_timestamp = datetime.now()
    
    db.commit()
    db.refresh(detection)
    
    return {
        "id": detection.id,
        "detection_id": detection.id,
        "feedback": detection.analyst_feedback,
        "notes": detection.analyst_notes,
        "timestamp": detection.feedback_timestamp
    }





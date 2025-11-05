from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from app.core.database import get_db
from app.models import schemas, database

router = APIRouter()


@router.get("/stats", response_model=schemas.StatsResponse)
async def get_stats(db: Session = Depends(get_db)):
    """Get system statistics."""
    # Total events
    total_events = db.query(func.count(database.Event.id)).scalar() or 0
    
    # Total detections
    total_detections = db.query(func.count(database.Detection.id)).scalar() or 0
    
    # Malicious detections
    malicious_detections = db.query(func.count(database.Detection.id)).filter(
        database.Detection.is_malicious == True
    ).scalar() or 0
    
    # False positives (malicious flagged but feedback says false positive)
    false_positives = db.query(func.count(database.Detection.id)).filter(
        and_(
            database.Detection.is_malicious == True,
            database.Detection.analyst_feedback == 'false_positive'
        )
    ).scalar() or 0
    
    # False negatives (not flagged but feedback says false negative)
    false_negatives = db.query(func.count(database.Detection.id)).filter(
        and_(
            database.Detection.is_malicious == False,
            database.Detection.analyst_feedback == 'false_negative'
        )
    ).scalar() or 0
    
    # Detection rate
    detection_rate = (malicious_detections / total_events * 100) if total_events > 0 else 0.0
    
    # False positive rate
    fp_rate = (false_positives / malicious_detections * 100) if malicious_detections > 0 else 0.0
    
    # Recent detections (last 10)
    recent_detections = db.query(database.Detection).filter(
        database.Detection.is_malicious == True
    ).order_by(database.Detection.timestamp.desc()).limit(10).all()
    
    recent_list = [
        {
            "id": d.id,
            "timestamp": d.timestamp.isoformat(),
            "score": d.malicious_score,
            "process": db.query(database.Event).filter(database.Event.id == d.event_id).first().process_name if db.query(database.Event).filter(database.Event.id == d.event_id).first() else "N/A"
        }
        for d in recent_detections
    ]
    
    return {
        "total_events": total_events,
        "total_detections": total_detections,
        "malicious_detections": malicious_detections,
        "false_positives": false_positives,
        "false_negatives": false_negatives,
        "detection_rate": round(detection_rate, 2),
        "false_positive_rate": round(fp_rate, 2),
        "recent_detections": recent_list
    }




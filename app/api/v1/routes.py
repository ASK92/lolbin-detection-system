from fastapi import APIRouter
from app.api.v1.endpoints import detections, stats

api_router = APIRouter()

api_router.include_router(detections.router, prefix="/api/v1", tags=["detections"])
api_router.include_router(stats.router, prefix="/api/v1", tags=["stats"])





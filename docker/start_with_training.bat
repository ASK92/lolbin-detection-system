@echo off
echo ==========================================
echo LOLBin Detection System - Full Deployment
echo ==========================================
echo.

REM Check if models exist
if not exist "data\models\random_forest_model.pkl" (
    echo Models not found. Training models with sample data...
    echo.
    
    REM Check if sample data exists
    if not exist "data\processed\sample_data.csv" (
        echo Sample data not found. Generating sample data...
        docker-compose run --rm backend python scripts/create_sample_data.py --benign 1000 --malicious 200 --output data/processed/sample_data.csv
    )
    
    echo Training models...
    docker-compose run --rm backend python scripts/train_models.py --data-path data/processed/sample_data.csv --random-forest --lstm
    echo.
)

echo Starting services...
docker-compose up -d

echo.
echo Waiting for services to be ready...
timeout /t 15 /nobreak >nul

echo.
echo ==========================================
echo Services started!
echo ==========================================
echo.
echo Frontend Dashboard: http://localhost:8501
echo Backend API: http://localhost:8000
echo API Documentation: http://localhost:8000/docs
echo.
echo To view logs: docker-compose logs -f
echo To stop: docker-compose down
echo.




@echo off
echo ==========================================
echo LOLBin Detection System - Docker Startup
echo ==========================================

REM Check if .env file exists
if not exist .env (
    echo WARNING: .env file not found. Creating from .env.example...
    if exist .env.example (
        copy .env.example .env
        echo Please edit .env file with your configuration before starting.
        echo At minimum, you need to set OPENAI_API_KEY
        exit /b 1
    ) else (
        echo ERROR: .env.example not found. Please create .env file manually.
        exit /b 1
    )
)

REM Create necessary directories
if not exist data\models mkdir data\models
if not exist data\raw mkdir data\raw
if not exist data\processed mkdir data\processed
if not exist logs mkdir logs

REM Build and start services
echo Building Docker images...
docker-compose build

echo Starting services...
docker-compose up -d

echo.
echo Waiting for services to be ready...
timeout /t 10 /nobreak >nul

REM Check service health
echo Checking service health...
docker-compose ps

echo.
echo ==========================================
echo Services started successfully!
echo ==========================================
echo.
echo Backend API: http://localhost:8000
echo Frontend Dashboard: http://localhost:8501
echo API Documentation: http://localhost:8000/docs
echo.
echo To view logs: docker-compose logs -f
echo To stop services: docker-compose down
echo.





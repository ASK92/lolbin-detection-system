#!/bin/bash
set -e

echo "=========================================="
echo "LOLBin Detection System - Full Deployment"
echo "=========================================="

# Check if models exist
if [ ! -f "data/models/random_forest_model.pkl" ] || [ ! -f "data/models/lstm_model.pth" ]; then
    echo "Models not found. Training models with sample data..."
    
    # Check if sample data exists
    if [ ! -f "data/processed/sample_data.csv" ]; then
        echo "Sample data not found. Generating sample data..."
        docker-compose run --rm backend python scripts/create_sample_data.py \
            --benign 1000 --malicious 200 --output data/processed/sample_data.csv
    fi
    
    echo "Training models..."
    docker-compose run --rm backend python scripts/train_models.py \
        --data-path data/processed/sample_data.csv \
        --random-forest --lstm
fi

echo "Starting services..."
docker-compose up -d

echo ""
echo "Waiting for services to be ready..."
sleep 15

echo ""
echo "=========================================="
echo "Services started!"
echo "=========================================="
echo ""
echo "Frontend Dashboard: http://localhost:8501"
echo "Backend API: http://localhost:8000"
echo "API Documentation: http://localhost:8000/docs"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: docker-compose down"
echo ""




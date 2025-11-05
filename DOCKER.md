# Docker Deployment Guide

This guide covers deploying the LOLBin Detection System using Docker and Docker Compose.

## Prerequisites

- Docker 20.10 or higher
- Docker Compose 2.0 or higher
- At least 4GB RAM available
- OpenAI API key (for explanations)

## Quick Start

### 1. Clone and Configure

```bash
# Clone the repository
git clone <repository-url>
cd "ML Final Project"

# Copy environment file
cp .env.example .env

# Edit .env with your configuration
# At minimum, set OPENAI_API_KEY
nano .env  # or use your preferred editor
```

### 2. Start Services

```bash
# Make scripts executable (Linux/Mac)
chmod +x docker/start.sh docker/stop.sh

# Start all services
./docker/start.sh

# Or use docker-compose directly
docker-compose up -d
```

### 3. Access Services

- **Frontend Dashboard**: http://localhost:8501
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Database**: localhost:5432 (if needed)

### 4. Stop Services

```bash
./docker/stop.sh

# Or use docker-compose directly
docker-compose down
```

## Services

The Docker Compose setup includes three services:

1. **db** - PostgreSQL database
2. **backend** - FastAPI backend API
3. **frontend** - Streamlit dashboard

## Configuration

### Environment Variables

Edit `.env` file with your configuration:

```env
# Database (PostgreSQL)
POSTGRES_USER=lolbin
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=lolbin_detection

# OpenAI (Required)
OPENAI_API_KEY=your_openai_api_key
OPENAI_MODEL=gpt-4-turbo-preview

# Alerting (Optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
EMAIL_SMTP_HOST=smtp.gmail.com
EMAIL_SMTP_PORT=587
EMAIL_FROM=noreply@example.com
EMAIL_TO=security@example.com

# Detection Thresholds
DETECTION_THRESHOLD=0.7
ALERT_THRESHOLD=0.9

# Model Paths
RANDOM_FOREST_MODEL_PATH=data/models/random_forest_model.pkl
LSTM_MODEL_PATH=data/models/lstm_model.pth
```

### Database URL

The backend automatically uses PostgreSQL when running in Docker. The database URL is constructed from environment variables:

```
postgresql://POSTGRES_USER:POSTGRES_PASSWORD@db:5432/POSTGRES_DB
```

## Docker Compose Commands

### Start Services

```bash
# Start in background
docker-compose up -d

# Start with logs
docker-compose up

# Build and start
docker-compose up --build -d
```

### Stop Services

```bash
# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f db
```

### Service Management

```bash
# Restart a service
docker-compose restart backend

# Stop a service
docker-compose stop frontend

# Start a stopped service
docker-compose start frontend

# Rebuild a service
docker-compose build backend
docker-compose up -d backend
```

### Execute Commands

```bash
# Run a command in backend container
docker-compose exec backend python scripts/init_database.py

# Run a command in frontend container
docker-compose exec frontend python -c "print('Hello')"

# Access database
docker-compose exec db psql -U lolbin -d lolbin_detection
```

## Data Persistence

### Volumes

Data is persisted in Docker volumes:

- **postgres_data**: Database data
- **./data**: Model files and data
- **./logs**: Log files

### Backup Database

```bash
# Backup
docker-compose exec db pg_dump -U lolbin lolbin_detection > backup.sql

# Restore
docker-compose exec -T db psql -U lolbin lolbin_detection < backup.sql
```

## Model Training in Docker

### Option 1: Train Models Outside Docker

Train models locally, then copy to Docker:

```bash
# Train models locally
python scripts/train_models.py --data-path data/processed/training_data.csv --random-forest --lstm

# Models will be in data/models/ and will be available in Docker
```

### Option 2: Train Models Inside Docker

```bash
# Copy training data to container
docker cp data/processed/training_data.csv lolbin-backend:/app/data/processed/

# Run training
docker-compose exec backend python scripts/train_models.py \
    --data-path data/processed/training_data.csv \
    --random-forest --lstm

# Models will be saved in data/models/
```

## Development Mode

For development with hot-reload:

1. Create `docker-compose.override.yml`:

```yaml
version: '3.8'

services:
  backend:
    volumes:
      - ./app:/app/app
      - ./scripts:/app/scripts
    environment:
      - LOG_LEVEL=DEBUG
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

  frontend:
    volumes:
      - ./app/frontend:/app/frontend
```

2. Start services:

```bash
docker-compose up
```

Changes to code will be reflected automatically.

## Troubleshooting

### Services Won't Start

1. Check logs:
   ```bash
   docker-compose logs
   ```

2. Verify environment variables:
   ```bash
   docker-compose config
   ```

3. Check port availability:
   ```bash
   # Check if ports are in use
   netstat -an | grep 8000
   netstat -an | grep 8501
   netstat -an | grep 5432
   ```

### Database Connection Issues

1. Wait for database to be ready:
   ```bash
   docker-compose logs db
   ```

2. Check database connection:
   ```bash
   docker-compose exec backend python -c "from app.core.database import engine; engine.connect()"
   ```

### Frontend Can't Connect to Backend

1. Check backend URL in frontend:
   ```bash
   docker-compose exec frontend env | grep BACKEND_URL
   ```

2. Verify backend is running:
   ```bash
   curl http://localhost:8000/health
   ```

3. Check network connectivity:
   ```bash
   docker-compose exec frontend curl http://backend:8000/health
   ```

### Model Files Not Found

1. Ensure models are trained and in `data/models/`:
   ```bash
   ls -la data/models/
   ```

2. Check model paths in `.env`:
   ```bash
   grep MODEL_PATH .env
   ```

3. Train models if missing:
   ```bash
   docker-compose exec backend python scripts/train_models.py --data-path data/processed/training_data.csv --random-forest --lstm
   ```

### Memory Issues

If you encounter memory issues:

1. Increase Docker memory limit
2. Reduce batch sizes in model training
3. Use SQLite instead of PostgreSQL for development

## Production Deployment

### Security Considerations

1. **Use strong passwords** for database
2. **Secure API keys** - never commit `.env` to git
3. **Use HTTPS** - set up reverse proxy (Nginx/Traefik)
4. **Limit network exposure** - only expose necessary ports
5. **Regular updates** - keep Docker images updated

### Using Docker Swarm

For production with multiple nodes:

```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml lolbin-detection

# View services
docker service ls

# View logs
docker service logs lolbin-detection_backend
```

### Using Kubernetes

Convert docker-compose.yml to Kubernetes manifests using tools like `kompose`:

```bash
kompose convert
kubectl apply -f .
```

## Performance Tuning

### Resource Limits

Add resource limits to `docker-compose.yml`:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
```

### Scaling

Scale backend service:

```bash
docker-compose up -d --scale backend=3
```

## Monitoring

### Health Checks

Services include health checks. View status:

```bash
docker-compose ps
```

### Metrics

Monitor container resource usage:

```bash
docker stats
```

## Clean Up

Remove everything:

```bash
# Stop and remove containers
docker-compose down

# Remove volumes (WARNING: deletes data)
docker-compose down -v

# Remove images
docker-compose down --rmi all

# Clean up system
docker system prune -a
```

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- Main README.md for system overview
- DEPLOYMENT.md for non-Docker deployment





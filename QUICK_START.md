# Quick Start Guide - Docker Deployment

## Step 1: Build and Start Services

```bash
docker-compose up -d --build
```

This will:
- Build all Docker images
- Start PostgreSQL database
- Start backend API
- Start frontend dashboard

## Step 2: Train Models (if not already done)

```bash
# Generate sample data
docker-compose run --rm backend python scripts/create_sample_data.py \
    --benign 1000 --malicious 200 --output data/processed/sample_data.csv

# Train models
docker-compose run --rm backend python scripts/train_models.py \
    --data-path data/processed/sample_data.csv --random-forest --lstm
```

## Step 3: Access Services

Once containers are running:

- **Frontend Dashboard**: http://localhost:8501
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

## Step 4: Check Status

```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
```

## Troubleshooting

### If backend fails health check:

1. Check logs: `docker-compose logs backend`
2. Ensure models are trained (see Step 2)
3. Restart services: `docker-compose restart`

### If frontend can't connect to backend:

1. Check backend is running: `docker-compose ps`
2. Verify backend URL in frontend container environment
3. Check network connectivity: `docker-compose exec frontend curl http://backend:8000/health`

## Stop Services

```bash
docker-compose down
```

## Clean Up Everything

```bash
docker-compose down -v  # Removes volumes too
```



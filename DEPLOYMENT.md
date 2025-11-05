# Deployment Guide

This guide covers deployment of the LOLBin Detection System in production and development environments.

## Prerequisites

- Python 3.10 or higher
- PostgreSQL 14+ (for production) or SQLite (for development)
- Windows VM with Sysmon installed (for data collection)
- OpenAI API key (for natural language explanations)
- Slack webhook URL (optional, for alerting)

## Development Setup

### 1. Clone and Install

```bash
git clone <repository-url>
cd ML\ Final\ Project
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your configuration:
- Database connection string
- OpenAI API key
- Slack webhook URL (optional)
- Model paths
- Detection thresholds

### 3. Initialize Database

```bash
python scripts/init_database.py
```

### 4. Generate Sample Data (for testing)

```bash
python scripts/create_sample_data.py --benign 1000 --malicious 200
```

### 5. Train Models

```bash
python scripts/train_models.py --data-path data/processed/sample_data.csv --random-forest --lstm
```

### 6. Start Backend API

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 7. Start Frontend Dashboard

```bash
streamlit run app/frontend/dashboard.py
```

## Production Deployment

### Architecture Overview

The system consists of three main components:
1. **Backend API** (FastAPI) - Detection and explainability service
2. **Event Collector** - Runs on Windows endpoints to stream events
3. **Frontend Dashboard** (Streamlit) - Real-time monitoring and analysis

### Backend Deployment

#### Option 1: Docker Deployment

Create `Dockerfile`:

```dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Build and run:

```bash
docker build -t lolbin-detection .
docker run -d -p 8000:8000 --env-file .env lolbin-detection
```

#### Option 2: Systemd Service

Create `/etc/systemd/system/lolbin-detection.service`:

```ini
[Unit]
Description=LOLBin Detection API
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/lolbin-detection
Environment="PATH=/opt/lolbin-detection/venv/bin"
ExecStart=/opt/lolbin-detection/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable lolbin-detection
sudo systemctl start lolbin-detection
```

#### Option 3: Nginx Reverse Proxy

Configure Nginx as reverse proxy:

```nginx
server {
    listen 80;
    server_name detection.example.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Event Collector Deployment

On Windows endpoints:

1. Install Python 3.10+
2. Install dependencies: `pip install -r requirements.txt`
3. Configure backend URL in `.env` or command line
4. Run collector as Windows service or scheduled task

For Windows Service:

```powershell
# Install as service using NSSM
nssm install LOLBinCollector "C:\Python310\python.exe" "C:\path\to\collectors\windows_event_collector.py"
nssm set LOLBinCollector AppParameters "--mode realtime"
nssm start LOLBinCollector
```

### Frontend Deployment

#### Option 1: Streamlit Cloud

Deploy to Streamlit Cloud or similar platform.

#### Option 2: Docker

Create `Dockerfile.frontend`:

```dockerfile
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/frontend ./app/frontend

CMD ["streamlit", "run", "app/frontend/dashboard.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

#### Option 3: Standalone Server

Run on dedicated server with Nginx reverse proxy:

```nginx
server {
    listen 8501;
    server_name dashboard.example.com;

    location / {
        proxy_pass http://127.0.0.1:8501;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Data Collection Setup

### Windows VM Configuration

1. Install Windows 10/11 VM
2. Install Sysmon:
   ```powershell
   sysmon.exe -i -accepteula
   ```
3. Apply SwiftOnSecurity Sysmon configuration:
   ```powershell
   sysmon.exe -c sysmonconfig.xml
   ```
4. Enable PowerShell script block logging (Group Policy)
5. Configure Sysmon to log Event IDs: 1, 7, 10, 11, 13, 22

### Collecting Training Data

1. **Benign Data Collection:**
   - Operate VM normally for 1 week
   - Use standard applications and tools
   - Export logs regularly using event collector

2. **Malicious Data Generation:**
   - Run controlled LOLBin attacks
   - Use LOLBAS techniques
   - Document each execution
   - Label all malicious samples

3. **External Datasets:**
   - Download sbousseaden/EVTX-ATTACK-SAMPLES from GitHub
   - Download COMISET from Zenodo
   - Process using `scripts/process_evtx_files.py`

### Data Processing

```bash
# Process EVTX files
python scripts/process_evtx_files.py --input-dir data/raw/benign --output-dir data/processed/ --label 0
python scripts/process_evtx_files.py --input-dir data/raw/malicious --output-dir data/processed/ --label 1

# Combine datasets
cat data/processed/benign_events.csv data/processed/malicious_events.csv > data/processed/training_data.csv

# Train models
python scripts/train_models.py --data-path data/processed/training_data.csv --random-forest --lstm
```

## Monitoring and Maintenance

### Logging

Logs are written to `logs/app.log` by default. Configure log rotation:

```python
# In app/core/config.py
LOG_LEVEL = "INFO"
LOG_FILE = "logs/app.log"
LOG_ROTATION = "daily"
LOG_RETENTION = 30
```

### Database Maintenance

Regular database maintenance:

```sql
-- PostgreSQL
VACUUM ANALYZE detections;
REINDEX TABLE detections;

-- SQLite
VACUUM;
```

### Model Updates

Retrain models periodically with new data:

```bash
python scripts/train_models.py --data-path data/processed/updated_training_data.csv --random-forest --lstm
```

Replace model files and restart backend service.

## Security Considerations

1. **API Security:**
   - Use HTTPS in production
   - Implement authentication (JWT tokens)
   - Rate limiting
   - Input validation

2. **Database Security:**
   - Use strong passwords
   - Encrypt connections
   - Regular backups
   - Access control

3. **Secrets Management:**
   - Use environment variables or secrets manager
   - Never commit `.env` files
   - Rotate API keys regularly

4. **Network Security:**
   - Firewall rules
   - VPN for collector connections
   - Network segmentation

## Troubleshooting

### Backend Not Starting

- Check database connection
- Verify model files exist
- Check log files for errors
- Ensure port 8000 is available

### Models Not Loading

- Verify model file paths in `.env`
- Check model file permissions
- Ensure models are trained and saved correctly

### Event Collector Issues

- Verify Sysmon is installed and running
- Check event log permissions
- Test backend API connectivity
- Review collector logs

### Frontend Not Connecting

- Verify backend URL configuration
- Check CORS settings
- Test API endpoints directly
- Review browser console for errors

## Performance Tuning

### Database Optimization

- Add indexes on frequently queried columns
- Use connection pooling
- Regular VACUUM/ANALYZE

### API Performance

- Use async endpoints where possible
- Implement caching for stats endpoints
- Rate limiting
- Load balancing for high traffic

### Model Inference

- Use GPU for LSTM inference if available
- Batch processing for multiple events
- Model quantization for faster inference

## Backup and Recovery

### Database Backups

```bash
# PostgreSQL
pg_dump -U user -d lolbin_detection > backup_$(date +%Y%m%d).sql

# SQLite
cp lolbin_detection.db backup_$(date +%Y%m%d).db
```

### Model Backups

```bash
cp -r data/models/ backups/models_$(date +%Y%m%d)/
```

### Recovery Procedures

1. Restore database from backup
2. Restore model files
3. Restart services
4. Verify functionality





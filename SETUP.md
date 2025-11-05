# Quick Setup Guide

This guide provides a quick start for setting up the LOLBin Detection System.

## Prerequisites

- Python 3.10 or higher
- pip package manager
- PostgreSQL (optional, SQLite works for development)

## Installation Steps

### 1. Create Virtual Environment

```bash
python -m venv venv
```

On Windows:
```powershell
.\venv\Scripts\activate
```

On Linux/Mac:
```bash
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your settings
# Required: OPENAI_API_KEY
# Optional: Database URL, Slack webhook, Email settings
```

### 4. Initialize Database

```bash
python scripts/init_database.py
```

### 5. Generate Sample Data (for testing)

```bash
python scripts/create_sample_data.py --benign 1000 --malicious 200
```

### 6. Train Models (with sample data)

```bash
python scripts/train_models.py --data-path data/processed/sample_data.csv --random-forest --lstm
```

### 7. Start Backend API

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Or:
```bash
python app/main.py
```

### 8. Start Frontend Dashboard

In a new terminal:
```bash
streamlit run app/frontend/dashboard.py
```

### 9. Test the System

1. Open browser to http://localhost:8501
2. Navigate to "Manual Analysis" page
3. Submit a test event:
   - Process: `powershell.exe`
   - Command Line: `powershell -Command Get-Process`
   - Click "Analyze Event"
4. View detection results in "Detection Details" page

## Next Steps

For production deployment and real data collection, see:
- `USER_TASKS.md` - Tasks you need to complete
- `DEPLOYMENT.md` - Production deployment guide
- `README.md` - Full documentation

## Troubleshooting

### Import Errors

If you see import errors, ensure:
1. Virtual environment is activated
2. All dependencies are installed: `pip install -r requirements.txt`

### Model Errors

If models fail to load:
1. Ensure models are trained: `python scripts/train_models.py --data-path data/processed/sample_data.csv --random-forest --lstm`
2. Check model paths in `.env` file
3. Verify model files exist in `data/models/`

### Database Errors

If database errors occur:
1. Run initialization: `python scripts/init_database.py`
2. Check database URL in `.env` file
3. Ensure database server is running (for PostgreSQL)

### API Connection Errors

If frontend cannot connect to backend:
1. Verify backend is running on port 8000
2. Check `BACKEND_URL` in Streamlit secrets or environment
3. Test API directly: `curl http://localhost:8000/health`




# LOLBin Detection and Explanation System

A production-grade, real-time system for detecting Living Off The Land Binary (LOLBin) attacks using machine learning with integrated explainability features.

## System Architecture

The system consists of the following components:

- **Event Collector**: Python agent that streams Sysmon events from Windows endpoints
- **Detection Backend**: FastAPI service performing ML inference and explainability
- **Database**: PostgreSQL (production) or SQLite (development) for event storage
- **Frontend**: Streamlit dashboard for real-time monitoring and analysis
- **Alerting**: Slack/Email notifications for high-priority detections

## Prerequisites

- Python 3.10+
- PostgreSQL 14+ (for production) or SQLite (for development)
- Windows VM with Sysmon installed (for data collection)
- OpenAI API key (for natural language explanations)
- Slack webhook URL (optional, for alerting)

## Installation

### Option 1: Docker (Recommended)

The easiest way to deploy the system is using Docker:

1. Clone the repository and navigate to the project directory

2. Copy environment configuration:
```bash
cp .env.example .env
```

3. Edit `.env` with your configuration (at minimum, set `OPENAI_API_KEY`)

4. Start services:
```bash
docker-compose up -d
```

The website will be available at http://localhost:8501

See `DOCKER.md` for detailed Docker deployment instructions.

### Option 2: Local Installation

1. Clone the repository and navigate to the project directory

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Copy environment configuration:
```bash
cp .env.example .env
```

5. Edit `.env` with your configuration:
- Database connection strings
- OpenAI API key
- Slack webhook URL (optional)
- Model paths and thresholds

6. Initialize the database:
```bash
python scripts/init_database.py
```

7. Train initial models (after data collection):
```bash
python scripts/train_models.py --data-path data/processed/
```

## Data Collection Requirements

### What You Need to Do

1. **Set up Windows VM with Sysmon**
   - Install Windows 10/11 VM (local, cloud, or Azure)
   - Install Sysmon with SwiftOnSecurity configuration
   - Enable PowerShell script block logging (Event ID 4104)
   - Configure Sysmon to log Event IDs: 1, 7, 10, 11, 13, 22

2. **Collect Benign Baseline Data**
   - Operate VM normally for approximately 1 week
   - Activities: web browsing, Office usage, Windows Updates, legitimate software installation, PowerShell maintenance
   - Expected volume: 30,000-50,000 events
   - Export logs using WinLogBeat or PowerShell EVTX parser

3. **Generate Labeled Attack Data**
   - Execute controlled malicious samples using LOLBin techniques
   - Use LOLBAS references, invoke Empire/Nishang/PowerSploit
   - Simulate lateral movement, credential dumping, fileless persistence
   - Document each execution: timestamp, script, technique
   - Label all malicious samples appropriately

4. **Download External Datasets**
   - sbousseaden/EVTX-ATTACK-SAMPLES from GitHub
   - COMISET from Zenodo (relevant subsets)
   - Verify feature compatibility and label appropriately

5. **Preprocess and Normalize Data**
   - Run preprocessing scripts to extract features
   - Normalize to common schema
   - Split into training/validation/test sets

## Usage

### Docker Deployment (Recommended)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

Access the dashboard at http://localhost:8501

### Local Deployment

#### Starting the Backend API

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

#### Starting the Event Collector

On Windows endpoint:
```bash
python collectors/windows_event_collector.py
```

#### Starting the Frontend Dashboard

```bash
streamlit run app/frontend/dashboard.py
```

### Processing Historical Data

```bash
python scripts/process_evtx_files.py --input-dir data/raw/ --output-dir data/processed/
```

## API Endpoints

- `POST /api/v1/events` - Submit event for detection
- `GET /api/v1/detections` - List all detections
- `GET /api/v1/detections/{id}` - Get detection details with explanations
- `POST /api/v1/feedback` - Submit analyst feedback
- `GET /api/v1/stats` - Get system statistics

## Project Structure

```
.
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── endpoints/
│   │       └── routes.py
│   ├── core/
│   │   ├── config.py
│   │   ├── database.py
│   │   └── security.py
│   ├── models/
│   │   ├── database.py
│   │   └── schemas.py
│   ├── services/
│   │   ├── detection.py
│   │   ├── explainability.py
│   │   └── alerting.py
│   ├── ml/
│   │   ├── feature_extraction.py
│   │   ├── random_forest_model.py
│   │   └── lstm_model.py
│   └── frontend/
│       └── dashboard.py
├── collectors/
│   └── windows_event_collector.py
├── scripts/
│   ├── init_database.py
│   ├── train_models.py
│   └── process_evtx_files.py
├── data/
│   ├── raw/
│   ├── processed/
│   └── models/
├── tests/
└── requirements.txt
```

## Configuration

Key configuration options in `.env`:

- `DATABASE_URL`: PostgreSQL connection string
- `OPENAI_API_KEY`: OpenAI API key for explanations
- `SLACK_WEBHOOK_URL`: Slack webhook for alerts
- `DETECTION_THRESHOLD`: ML score threshold (default: 0.7)
- `ALERT_THRESHOLD`: Alert threshold (default: 0.9)

## Development

Run tests:
```bash
pytest tests/
```

Run linting:
```bash
flake8 app/
black app/
```

## License

Proprietary - All rights reserved


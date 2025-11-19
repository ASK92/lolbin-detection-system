# Model Training Guide

Complete guide for training LOLBin detection models using your collected data.

## Models Overview

This system uses **two machine learning models** for LOLBin detection:

### 1. **Random Forest Classifier** (Primary Model)
- **Type**: Ensemble learning (tree-based)
- **Best for**: Fast inference, interpretable results, good baseline
- **Advantages**: 
  - Fast training and prediction
  - Handles non-linear relationships
  - Feature importance analysis
  - Works well with structured features
- **Use case**: Real-time detection, production deployment

### 2. **LSTM (Long Short-Term Memory)** (Deep Learning Model)
- **Type**: Recurrent Neural Network
- **Best for**: Sequence patterns, temporal relationships
- **Advantages**:
  - Can learn complex patterns
  - Handles sequential data
  - Better for advanced evasion techniques
- **Use case**: Advanced detection, research, improving accuracy

## Complete Training Workflow

### Step 1: Process Your EVTX Files

First, convert your EVTX files to CSV format with extracted features:

```bash
# Process benign data (Label 0)
python scripts/process_evtx_files.py \
    --input-dir data/Sysmon_logs \
    --output-dir data/processed/benign \
    --label 0 \
    --format csv

# Process malicious data (Label 1) - after you collect it
python scripts/process_evtx_files.py \
    --input-dir data/raw/malicious \
    --output-dir data/processed/malicious \
    --label 1 \
    --format csv
```

**What this does:**
- Parses EVTX files
- Extracts events with command lines (Event ID 1)
- Extracts: command_line, process_name, parent_image, user, integrity_level
- Labels events (0=benign, 1=malicious)
- Saves to CSV format

### Step 2: Combine Datasets

Combine benign and malicious data:

```bash
# Using Python (recommended)
python -c "
import pandas as pd
benign = pd.read_csv('data/processed/benign/events.csv')
malicious = pd.read_csv('data/processed/malicious/events.csv')
combined = pd.concat([benign, malicious], ignore_index=True)
combined.to_csv('data/processed/training_data.csv', index=False)
print(f'Combined dataset: {len(combined)} events')
print(f'  Benign: {len(benign)} events')
print(f'  Malicious: {len(malicious)} events')
"
```

Or manually:
```powershell
# PowerShell
$benign = Import-Csv "data/processed/benign/events.csv"
$malicious = Import-Csv "data/processed/malicious/events.csv"
$combined = $benign + $malicious
$combined | Export-Csv "data/processed/training_data.csv" -NoTypeInformation
```

### Step 3: Train Models

#### Train Random Forest (Recommended to start)

```bash
python scripts/train_models.py \
    --data-path data/processed/training_data.csv \
    --random-forest \
    --test-size 0.2
```

#### Train LSTM (Requires PyTorch)

```bash
python scripts/train_models.py \
    --data-path data/processed/training_data.csv \
    --lstm \
    --test-size 0.2
```

#### Train Both Models

```bash
python scripts/train_models.py \
    --data-path data/processed/training_data.csv \
    --random-forest \
    --lstm \
    --test-size 0.2
```

### Step 4: Evaluate Models

The training script automatically:
- Splits data (80% train, 20% test)
- Trains the model
- Evaluates on test set
- Shows accuracy, precision, recall, F1-score
- Displays confusion matrix
- Saves the trained model

## Feature Extraction

The system extracts **30+ features** from each event:

### Process Features
- Is LOLBin process (powershell.exe, cmd.exe, etc.)
- Is PowerShell, CMD, WMIC, scripting tool
- Process name characteristics

### Command Line Features
- Command line length and token count
- Suspicious pattern count (encoded commands, base64, etc.)
- Has encoded command, network activity, file operations
- Registry operations, process creation
- Entropy (randomness measure)
- Character ratios (digits, uppercase, special chars)
- URL and IP address detection

### Context Features
- Parent process information
- User account type
- Integrity level (High/Medium/Low)
- Argument count and complexity

### Example Features:
```python
{
    'command_line_length': 156.0,
    'is_lolbin_process': 1.0,  # powershell.exe
    'suspicious_pattern_count': 2.0,  # Found -enc and base64
    'has_encoded_command': 1.0,
    'command_line_entropy': 5.2,  # High entropy = suspicious
    'has_network_activity': 1.0,
    'is_high_integrity': 0.0,
    ...
}
```

## Model Architecture

### Random Forest
```
Input: 30+ features per event
↓
100 Decision Trees (n_estimators=100)
↓
Voting/Averaging
↓
Output: Malicious probability (0.0 - 1.0)
```

**Parameters:**
- `n_estimators`: 100 trees
- `max_depth`: 20 levels
- `min_samples_split`: 5 samples
- `random_state`: 42 (reproducible)

### LSTM
```
Input: 30+ features per event
↓
LSTM Layer 1 (128 hidden units)
↓
LSTM Layer 2 (128 hidden units)
↓
Dense Layer (64 units) + ReLU + Dropout
↓
Output Layer (1 unit) + Sigmoid
↓
Output: Malicious probability (0.0 - 1.0)
```

**Parameters:**
- `hidden_size`: 128
- `num_layers`: 2
- `dropout`: 0.2
- `learning_rate`: 0.001
- `epochs`: 50
- `batch_size`: 32

## Training Requirements

### Data Requirements

**Minimum:**
- 1,000+ benign events (Label 0)
- 200+ malicious events (Label 1)
- Total: 1,200+ events

**Recommended:**
- 10,000+ benign events
- 1,000+ malicious events
- Total: 11,000+ events

**Optimal:**
- 50,000+ benign events
- 5,000+ malicious events
- Total: 55,000+ events

### Current Status

You have:
- ✅ ~37,000 Sysmon events (benign)
- ⏳ Need to collect malicious data (LOLBin attacks)

### Dependencies

```bash
# Install required packages
pip install pandas numpy scikit-learn joblib torch python-evtx
```

## Training Output

After training, you'll see:

```
Training Random Forest model...
Random Forest Accuracy: 0.9234

Classification Report:
              precision    recall  f1-score   support

           0       0.95      0.98      0.96      2000
           1       0.87      0.75      0.81       400

    accuracy                           0.92      2400
   macro avg       0.91      0.86      0.88      2400
weighted avg       0.92      0.92      0.92      2400

Confusion Matrix:
[[1960   40]
 [ 100  300]]

Random Forest model saved to models/random_forest_model.pkl
```

## Model Files

After training, models are saved to:
- Random Forest: `models/random_forest_model.pkl`
- LSTM: `models/lstm_model.pth`

These files are used by the detection system for real-time analysis.

## Quick Start Commands

### Complete Workflow (Once you have malicious data)

```bash
# 1. Process benign data
python scripts/process_evtx_files.py \
    --input-dir data/Sysmon_logs \
    --output-dir data/processed/benign \
    --label 0

# 2. Process malicious data
python scripts/process_evtx_files.py \
    --input-dir data/raw/malicious \
    --output-dir data/processed/malicious \
    --label 1

# 3. Combine datasets
python -c "
import pandas as pd
b = pd.read_csv('data/processed/benign/events.csv')
m = pd.read_csv('data/processed/malicious/events.csv')
pd.concat([b, m]).to_csv('data/processed/training_data.csv', index=False)
print(f'Combined: {len(b)} benign + {len(m)} malicious = {len(b)+len(m)} total')
"

# 4. Train Random Forest
python scripts/train_models.py \
    --data-path data/processed/training_data.csv \
    --random-forest

# 5. Train LSTM (optional)
python scripts/train_models.py \
    --data-path data/processed/training_data.csv \
    --lstm
```

## Next Steps

1. **Continue benign collection** (you're doing this ✅)
2. **Collect malicious data** (LOLBin attacks) - we'll create the script next
3. **Process both datasets**
4. **Train models**
5. **Deploy for detection**

## Troubleshooting

### "No events extracted"
- Check if EVTX files contain Event ID 1 (Process Creation)
- Verify files are not corrupted
- Ensure python-evtx is installed

### "Insufficient data"
- Need both benign and malicious samples
- Minimum 1,200 total events recommended
- More data = better model performance

### "Model accuracy is low"
- Collect more diverse data
- Ensure balanced dataset (not too skewed)
- Check feature extraction is working
- Verify labels are correct









import torch
import torch.nn as nn
import numpy as np
from typing import Dict, Any, List
from pathlib import Path
from app.ml.feature_extraction import FeatureExtractor


class LSTMModel(nn.Module):
    """LSTM model architecture for sequence-based detection."""
    
    def __init__(self, input_size: int, hidden_size: int = 128, num_layers: int = 2, dropout: float = 0.2):
        super(LSTMModel, self).__init__()
        self.hidden_size = hidden_size
        self.num_layers = num_layers
        
        self.lstm = nn.LSTM(
            input_size=input_size,
            hidden_size=hidden_size,
            num_layers=num_layers,
            dropout=dropout if num_layers > 1 else 0,
            batch_first=True
        )
        
        self.fc1 = nn.Linear(hidden_size, 64)
        self.relu = nn.ReLU()
        self.dropout = nn.Dropout(dropout)
        self.fc2 = nn.Linear(64, 1)
        self.sigmoid = nn.Sigmoid()
    
    def forward(self, x):
        lstm_out, _ = self.lstm(x)
        last_output = lstm_out[:, -1, :]
        x = self.fc1(last_output)
        x = self.relu(x)
        x = self.dropout(x)
        x = self.fc2(x)
        x = self.sigmoid(x)
        return x


class LSTMDetector:
    """LSTM model for LOLBin detection."""
    
    def __init__(self, model_path: str = None, device: str = None):
        self.model_path = model_path
        self.device = device or ('cuda' if torch.cuda.is_available() else 'cpu')
        self.model = None
        self.feature_extractor = FeatureExtractor()
        self.feature_names = None
        self.input_size = None
        self.is_loaded = False
    
    def load_model(self, model_path: str = None):
        """Load trained LSTM model."""
        if model_path:
            self.model_path = model_path
        
        if not self.model_path or not Path(self.model_path).exists():
            raise FileNotFoundError(f"Model file not found: {self.model_path}")
        
        checkpoint = torch.load(self.model_path, map_location=self.device)
        
        self.input_size = checkpoint.get('input_size', len(self.feature_extractor.get_feature_names()))
        hidden_size = checkpoint.get('hidden_size', 128)
        num_layers = checkpoint.get('num_layers', 2)
        
        self.model = LSTMModel(
            input_size=self.input_size,
            hidden_size=hidden_size,
            num_layers=num_layers
        )
        
        self.model.load_state_dict(checkpoint['model_state_dict'])
        self.model.to(self.device)
        self.model.eval()
        
        self.feature_names = checkpoint.get('feature_names', self.feature_extractor.get_feature_names())
        self.is_loaded = True
    
    def predict(self, event_data: Dict[str, Any]) -> Dict[str, Any]:
        """Predict malicious score for event."""
        if not self.is_loaded:
            raise ValueError("Model not loaded. Call load_model() first.")
        
        # Extract features
        features = self.feature_extractor.extract_features(event_data)
        
        # Convert to feature vector
        feature_vector = np.array([features.get(name, 0.0) for name in self.feature_names], dtype=np.float32)
        
        # Reshape for LSTM: (batch_size, sequence_length, input_size)
        # For single event, we use sequence_length=1
        feature_tensor = torch.FloatTensor(feature_vector).unsqueeze(0).unsqueeze(0).to(self.device)
        
        with torch.no_grad():
            output = self.model(feature_tensor)
            malicious_score = float(output.cpu().numpy()[0][0])
        
        return {
            'score': malicious_score,
            'features': features,
            'feature_vector': feature_vector.tolist()
        }
    
    def train(self, X: np.ndarray, y: np.ndarray, feature_names: List[str], **kwargs):
        """Train LSTM model."""
        hidden_size = kwargs.get('hidden_size', 128)
        num_layers = kwargs.get('num_layers', 2)
        dropout = kwargs.get('dropout', 0.2)
        learning_rate = kwargs.get('learning_rate', 0.001)
        epochs = kwargs.get('epochs', 50)
        batch_size = kwargs.get('batch_size', 32)
        
        self.input_size = X.shape[1]
        self.feature_names = feature_names
        
        self.model = LSTMModel(
            input_size=self.input_size,
            hidden_size=hidden_size,
            num_layers=num_layers,
            dropout=dropout
        )
        self.model.to(self.device)
        
        # Reshape for LSTM: (batch_size, sequence_length, input_size)
        X_tensor = torch.FloatTensor(X).unsqueeze(1).to(self.device)
        y_tensor = torch.FloatTensor(y).unsqueeze(1).to(self.device)
        
        criterion = nn.BCELoss()
        optimizer = torch.optim.Adam(self.model.parameters(), lr=learning_rate)
        
        dataset = torch.utils.data.TensorDataset(X_tensor, y_tensor)
        dataloader = torch.utils.data.DataLoader(dataset, batch_size=batch_size, shuffle=True)
        
        self.model.train()
        for epoch in range(epochs):
            epoch_loss = 0.0
            for batch_X, batch_y in dataloader:
                optimizer.zero_grad()
                outputs = self.model(batch_X)
                loss = criterion(outputs, batch_y)
                loss.backward()
                optimizer.step()
                epoch_loss += loss.item()
            
            if (epoch + 1) % 10 == 0:
                print(f"Epoch {epoch + 1}/{epochs}, Loss: {epoch_loss / len(dataloader):.4f}")
        
        self.model.eval()
        self.is_loaded = True
    
    def save_model(self, model_path: str):
        """Save trained model."""
        if not self.model:
            raise ValueError("No model to save. Train model first.")
        
        checkpoint = {
            'model_state_dict': self.model.state_dict(),
            'input_size': self.input_size,
            'hidden_size': self.model.hidden_size,
            'num_layers': self.model.num_layers,
            'feature_names': self.feature_names
        }
        
        Path(model_path).parent.mkdir(parents=True, exist_ok=True)
        torch.save(checkpoint, model_path)
        self.model_path = model_path





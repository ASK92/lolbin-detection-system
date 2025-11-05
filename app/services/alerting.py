import requests
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Dict, Any, Optional
from app.core.config import settings
from app.models.schemas import DetectionResponse
import logging

logger = logging.getLogger(__name__)


class AlertingService:
    """Service for sending alerts via Slack and Email."""
    
    def __init__(self):
        self.slack_webhook_url = settings.slack_webhook_url
        self.email_config = {
            'host': settings.email_smtp_host,
            'port': settings.email_smtp_port,
            'from': settings.email_from,
            'to': settings.email_to,
            'username': settings.email_username,
            'password': settings.email_password
        }
    
    def send_alert(self, detection: DetectionResponse, event_data: Dict[str, Any]) -> bool:
        """Send alert for high-priority detection."""
        if detection.malicious_score < settings.alert_threshold:
            return False
        
        success = False
        
        # Send Slack alert
        if self.slack_webhook_url:
            try:
                self._send_slack_alert(detection, event_data)
                success = True
            except Exception as e:
                logger.error(f"Slack alert failed: {e}")
        
        # Send Email alert
        if self.email_config['host'] and self.email_config['from']:
            try:
                self._send_email_alert(detection, event_data)
                success = True
            except Exception as e:
                logger.error(f"Email alert failed: {e}")
        
        return success
    
    def _send_slack_alert(self, detection: DetectionResponse, event_data: Dict[str, Any]):
        """Send alert to Slack."""
        command_line = event_data.get('command_line', 'N/A')
        process_name = event_data.get('process_name', 'N/A')
        
        # Truncate long command lines
        if len(command_line) > 500:
            command_line = command_line[:500] + "..."
        
        # Determine severity
        if detection.malicious_score >= 0.95:
            severity = "CRITICAL"
            color = "danger"
        elif detection.malicious_score >= 0.85:
            severity = "HIGH"
            color = "warning"
        else:
            severity = "MEDIUM"
            color = "warning"
        
        payload = {
            "attachments": [
                {
                    "color": color,
                    "title": f"LOLBin Detection Alert - {severity}",
                    "fields": [
                        {
                            "title": "Detection ID",
                            "value": str(detection.id),
                            "short": True
                        },
                        {
                            "title": "Malicious Score",
                            "value": f"{detection.malicious_score:.4f}",
                            "short": True
                        },
                        {
                            "title": "Process",
                            "value": process_name,
                            "short": True
                        },
                        {
                            "title": "Random Forest Score",
                            "value": f"{detection.random_forest_score:.4f}",
                            "short": True
                        },
                        {
                            "title": "LSTM Score",
                            "value": f"{detection.lstm_score:.4f}",
                            "short": True
                        },
                        {
                            "title": "Command Line",
                            "value": f"```{command_line}```",
                            "short": False
                        }
                    ],
                    "footer": "LOLBin Detection System",
                    "ts": int(detection.timestamp.timestamp())
                }
            ]
        }
        
        if detection.openai_explanation:
            payload["attachments"][0]["fields"].append({
                "title": "Analysis",
                "value": detection.openai_explanation[:500] + ("..." if len(detection.openai_explanation) > 500 else ""),
                "short": False
            })
        
        response = requests.post(
            self.slack_webhook_url,
            json=payload,
            timeout=10
        )
        response.raise_for_status()
        logger.info(f"Slack alert sent for detection {detection.id}")
    
    def _send_email_alert(self, detection: DetectionResponse, event_data: Dict[str, Any]):
        """Send alert via email."""
        command_line = event_data.get('command_line', 'N/A')
        process_name = event_data.get('process_name', 'N/A')
        
        # Determine severity
        if detection.malicious_score >= 0.95:
            severity = "CRITICAL"
        elif detection.malicious_score >= 0.85:
            severity = "HIGH"
        else:
            severity = "MEDIUM"
        
        # Create email
        msg = MIMEMultipart()
        msg['From'] = self.email_config['from']
        msg['To'] = self.email_config['to']
        msg['Subject'] = f"LOLBin Detection Alert - {severity} (ID: {detection.id})"
        
        # Email body
        body = f"""
LOLBin Detection Alert

Detection Details:
- Detection ID: {detection.id}
- Severity: {severity}
- Malicious Score: {detection.malicious_score:.4f}
- Timestamp: {detection.timestamp}

Event Details:
- Process: {process_name}
- Command Line: {command_line}

Model Scores:
- Random Forest: {detection.random_forest_score:.4f}
- LSTM: {detection.lstm_score:.4f}

Analysis:
{detection.openai_explanation if detection.openai_explanation else 'Analysis not available'}

Please investigate this detection immediately.
"""
        
        msg.attach(MIMEText(body, 'plain'))
        
        # Send email
        server = smtplib.SMTP(self.email_config['host'], self.email_config['port'])
        server.starttls()
        
        if self.email_config['username'] and self.email_config['password']:
            server.login(self.email_config['username'], self.email_config['password'])
        
        server.send_message(msg)
        server.quit()
        
        logger.info(f"Email alert sent for detection {detection.id}")





import re
import math
from typing import Dict, Any, List
import numpy as np


class FeatureExtractor:
    """Extracts features from Windows event data for ML model inference."""
    
    # Common LOLBin process names
    LOLBIN_PROCESSES = {
        'powershell.exe', 'cmd.exe', 'wmic.exe', 'certutil.exe',
        'regsvr32.exe', 'mshta.exe', 'rundll32.exe', 'cscript.exe',
        'wscript.exe', 'bitsadmin.exe', 'schtasks.exe', 'sc.exe',
        'net.exe', 'netstat.exe', 'tasklist.exe', 'whoami.exe'
    }
    
    # Suspicious command patterns
    SUSPICIOUS_PATTERNS = [
        r'-enc|-e |-encodedcommand',
        r'base64',
        r'bypass|hidden|noprofile',
        r'iex|invoke-expression',
        r'downloadstring|downloadfile',
        r'frombase64string',
        r'new-object.*net\.webclient',
        r'wmi.*process.*create',
        r'reg.*add.*run',
        r'schtasks.*create.*\*',
        r'certutil.*-urlcache',
        r'bitsadmin.*transfer'
    ]
    
    def __init__(self):
        self.patterns = [re.compile(pattern, re.IGNORECASE) for pattern in self.SUSPICIOUS_PATTERNS]
    
    def extract_features(self, event_data: Dict[str, Any]) -> Dict[str, float]:
        """Extract feature vector from event data."""
        command_line = event_data.get('command_line', '').lower()
        process_name = event_data.get('process_name', '').lower()
        parent_image = event_data.get('parent_image', '').lower()
        
        features = {}
        
        # Basic features
        features['command_line_length'] = len(command_line)
        features['command_line_token_count'] = len(command_line.split())
        features['has_parent_process'] = 1.0 if parent_image else 0.0
        
        # Process name features
        features['is_lolbin_process'] = 1.0 if process_name in self.LOLBIN_PROCESSES else 0.0
        features['is_powershell'] = 1.0 if 'powershell' in process_name else 0.0
        features['is_cmd'] = 1.0 if 'cmd' in process_name else 0.0
        features['is_wmic'] = 1.0 if 'wmic' in process_name else 0.0
        features['is_scripting'] = 1.0 if any(x in process_name for x in ['cscript', 'wscript', 'mshta']) else 0.0
        
        # Command line features
        features['suspicious_pattern_count'] = self._count_suspicious_patterns(command_line)
        features['has_encoded_command'] = 1.0 if self._has_encoded_command(command_line) else 0.0
        features['has_network_activity'] = 1.0 if self._has_network_activity(command_line) else 0.0
        features['has_file_operation'] = 1.0 if self._has_file_operation(command_line) else 0.0
        features['has_registry_operation'] = 1.0 if self._has_registry_operation(command_line) else 0.0
        features['has_process_creation'] = 1.0 if self._has_process_creation(command_line) else 0.0
        
        # Entropy features
        features['command_line_entropy'] = self._calculate_entropy(command_line)
        features['has_high_entropy'] = 1.0 if features['command_line_entropy'] > 4.5 else 0.0
        
        # Character features
        features['rare_char_count'] = self._count_rare_characters(command_line)
        features['digit_ratio'] = self._calculate_digit_ratio(command_line)
        features['uppercase_ratio'] = self._calculate_uppercase_ratio(command_line)
        features['special_char_ratio'] = self._calculate_special_char_ratio(command_line)
        
        # URL and IP features
        features['has_url'] = 1.0 if self._has_url(command_line) else 0.0
        features['has_ip_address'] = 1.0 if self._has_ip_address(command_line) else 0.0
        
        # Parent process features
        features['parent_is_explorer'] = 1.0 if 'explorer' in parent_image else 0.0
        features['parent_is_svchost'] = 1.0 if 'svchost' in parent_image else 0.0
        features['parent_is_services'] = 1.0 if 'services' in parent_image else 0.0
        features['parent_is_lolbin'] = 1.0 if parent_image and any(x in parent_image for x in self.LOLBIN_PROCESSES) else 0.0
        
        # User and integrity features
        user = event_data.get('user', '').lower()
        integrity_level = event_data.get('integrity_level', '').lower()
        features['is_system_user'] = 1.0 if 'system' in user or 'nt authority' in user else 0.0
        features['is_high_integrity'] = 1.0 if 'high' in integrity_level else 0.0
        features['is_medium_integrity'] = 1.0 if 'medium' in integrity_level else 0.0
        features['is_low_integrity'] = 1.0 if 'low' in integrity_level else 0.0
        
        # Argument count and complexity
        features['argument_count'] = self._count_arguments(command_line)
        features['has_long_arguments'] = 1.0 if self._has_long_arguments(command_line) else 0.0
        
        # Temporal features (if available)
        timestamp = event_data.get('timestamp')
        if timestamp:
            # This would need actual timestamp parsing
            features['hour_of_day'] = 0.0  # Placeholder
            features['day_of_week'] = 0.0  # Placeholder
        
        return features
    
    def _count_suspicious_patterns(self, command_line: str) -> float:
        """Count occurrences of suspicious patterns."""
        count = sum(1 for pattern in self.patterns if pattern.search(command_line))
        return float(count)
    
    def _has_encoded_command(self, command_line: str) -> bool:
        """Check if command contains encoded content."""
        return bool(re.search(r'-enc|-e |-encodedcommand|base64', command_line, re.IGNORECASE))
    
    def _has_network_activity(self, command_line: str) -> bool:
        """Check if command involves network activity."""
        patterns = [
            r'http://|https://|ftp://',
            r'net\.webclient|downloadstring|downloadfile',
            r'wget|curl|invoke-webrequest',
            r'bitsadmin|certutil.*urlcache'
        ]
        return any(re.search(pattern, command_line, re.IGNORECASE) for pattern in patterns)
    
    def _has_file_operation(self, command_line: str) -> bool:
        """Check if command involves file operations."""
        patterns = [
            r'copy|move|del|rmdir|mkdir',
            r'type|cat|more|less',
            r'out-file|set-content|add-content'
        ]
        return any(re.search(pattern, command_line, re.IGNORECASE) for pattern in patterns)
    
    def _has_registry_operation(self, command_line: str) -> bool:
        """Check if command involves registry operations."""
        return bool(re.search(r'reg.*add|reg.*delete|reg.*query', command_line, re.IGNORECASE))
    
    def _has_process_creation(self, command_line: str) -> bool:
        """Check if command creates new processes."""
        patterns = [
            r'start-process|start|invoke-item',
            r'wmi.*process.*create',
            r'cmd.*\/c|powershell.*-command'
        ]
        return any(re.search(pattern, command_line, re.IGNORECASE) for pattern in patterns)
    
    def _calculate_entropy(self, text: str) -> float:
        """Calculate Shannon entropy of text."""
        if not text:
            return 0.0
        
        text = text.replace(' ', '')
        if not text:
            return 0.0
        
        char_counts = {}
        for char in text:
            char_counts[char] = char_counts.get(char, 0) + 1
        
        entropy = 0.0
        length = len(text)
        for count in char_counts.values():
            probability = count / length
            if probability > 0:
                entropy -= probability * math.log2(probability)
        
        return entropy
    
    def _count_rare_characters(self, text: str) -> float:
        """Count rare/uncommon characters."""
        rare_chars = set('~`!@#$%^&*()_+-=[]{}|;:,.<>?')
        count = sum(1 for char in text if char in rare_chars)
        return float(count)
    
    def _calculate_digit_ratio(self, text: str) -> float:
        """Calculate ratio of digits to total characters."""
        if not text:
            return 0.0
        digit_count = sum(1 for char in text if char.isdigit())
        return digit_count / len(text)
    
    def _calculate_uppercase_ratio(self, text: str) -> float:
        """Calculate ratio of uppercase letters to total letters."""
        letters = [c for c in text if c.isalpha()]
        if not letters:
            return 0.0
        uppercase_count = sum(1 for c in letters if c.isupper())
        return uppercase_count / len(letters)
    
    def _calculate_special_char_ratio(self, text: str) -> float:
        """Calculate ratio of special characters to total characters."""
        if not text:
            return 0.0
        special_chars = set('!@#$%^&*()_+-=[]{}|;:,.<>?/~`')
        special_count = sum(1 for char in text if char in special_chars)
        return special_count / len(text)
    
    def _has_url(self, text: str) -> bool:
        """Check if text contains URL."""
        return bool(re.search(r'https?://|ftp://', text, re.IGNORECASE))
    
    def _has_ip_address(self, text: str) -> bool:
        """Check if text contains IP address."""
        ip_pattern = r'\b(?:\d{1,3}\.){3}\d{1,3}\b'
        return bool(re.search(ip_pattern, text))
    
    def _count_arguments(self, command_line: str) -> float:
        """Count number of command-line arguments."""
        parts = command_line.split()
        # Remove executable name
        if parts:
            parts = parts[1:]
        return float(len(parts))
    
    def _has_long_arguments(self, command_line: str) -> bool:
        """Check if command has unusually long arguments."""
        parts = command_line.split()
        if len(parts) > 1:
            parts = parts[1:]  # Skip executable
            return any(len(part) > 100 for part in parts)
        return False
    
    def get_feature_names(self) -> List[str]:
        """Get list of feature names in order."""
        # Create a dummy event to extract feature names
        dummy_event = {
            'command_line': '',
            'process_name': '',
            'parent_image': '',
            'user': '',
            'integrity_level': '',
            'timestamp': None
        }
        features = self.extract_features(dummy_event)
        return list(features.keys())





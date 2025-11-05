import streamlit as st
import requests
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
from typing import Dict, Any, List
import json
import time

# Configuration
import os

# Try to get backend URL from environment variable (Docker) or Streamlit secrets
BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8000")

try:
    if not os.getenv("BACKEND_URL"):
        BACKEND_URL = st.secrets.get("BACKEND_URL", "http://localhost:8000")
except:
    pass

API_BASE = f"{BACKEND_URL}/api/v1"
REFRESH_INTERVAL = 30  # seconds


def get_detections(malicious_only: bool = False, limit: int = 100) -> List[Dict]:
    """Fetch detections from API."""
    try:
        params = {"malicious_only": malicious_only, "limit": limit}
        response = requests.get(f"{API_BASE}/detections", params=params, timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        st.error(f"Error fetching detections: {e}")
        return []


def get_detection(detection_id: int) -> Dict:
    """Fetch single detection by ID."""
    try:
        response = requests.get(f"{API_BASE}/detections/{detection_id}", timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        st.error(f"Error fetching detection: {e}")
        return {}


def get_stats() -> Dict:
    """Fetch system statistics."""
    try:
        response = requests.get(f"{API_BASE}/stats", timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        st.error(f"Error fetching stats: {e}")
        return {}


def submit_feedback(detection_id: int, feedback: str, notes: str = ""):
    """Submit analyst feedback."""
    try:
        payload = {
            "detection_id": detection_id,
            "feedback": feedback,
            "notes": notes
        }
        response = requests.post(f"{API_BASE}/feedback", json=payload, timeout=10)
        response.raise_for_status()
        return True
    except Exception as e:
        st.error(f"Error submitting feedback: {e}")
        return False


def submit_event(event_data: Dict):
    """Submit event for detection."""
    try:
        response = requests.post(f"{API_BASE}/events", json=event_data, timeout=30)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        st.error(f"Error submitting event: {e}")
        return None


def main():
    """Main dashboard application."""
    st.set_page_config(
        page_title="LOLBin Detection System",
        page_icon="🛡️",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    st.title("LOLBin Detection and Explanation System")
    st.markdown("---")
    
    # Sidebar
    st.sidebar.title("Navigation")
    page = st.sidebar.radio(
        "Select Page",
        ["Real-time Dashboard", "Detection Details", "Manual Analysis", "System Statistics"]
    )
    
    # Auto-refresh toggle
    auto_refresh = st.sidebar.checkbox("Auto-refresh", value=True)
    
    if auto_refresh:
        refresh_interval = st.sidebar.slider("Refresh Interval (seconds)", 10, 300, REFRESH_INTERVAL)
        if 'last_refresh' not in st.session_state:
            st.session_state.last_refresh = time.time()
        
        if time.time() - st.session_state.last_refresh > refresh_interval:
            st.session_state.last_refresh = time.time()
            st.rerun()
    
    # Main content
    if page == "Real-time Dashboard":
        render_dashboard()
    elif page == "Detection Details":
        render_detection_details()
    elif page == "Manual Analysis":
        render_manual_analysis()
    elif page == "System Statistics":
        render_statistics()


def render_dashboard():
    """Render real-time dashboard."""
    st.header("Real-time Detection Dashboard")
    
    # Filters
    col1, col2, col3 = st.columns(3)
    with col1:
        malicious_only = st.checkbox("Malicious Only", value=True)
    with col2:
        limit = st.slider("Number of Detections", 10, 500, 100)
    with col3:
        if st.button("Refresh"):
            st.rerun()
    
    # Fetch detections
    detections = get_detections(malicious_only=malicious_only, limit=limit)
    
    if not detections:
        st.info("No detections found.")
        return
    
    # Convert to DataFrame
    df = pd.DataFrame(detections)
    
    # Summary metrics
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Detections", len(detections))
    with col2:
        malicious_count = sum(1 for d in detections if d.get('is_malicious', False))
        st.metric("Malicious", malicious_count)
    with col3:
        avg_score = sum(d.get('malicious_score', 0) for d in detections) / len(detections) if detections else 0
        st.metric("Average Score", f"{avg_score:.3f}")
    with col4:
        high_risk = sum(1 for d in detections if d.get('malicious_score', 0) > 0.9)
        st.metric("High Risk", high_risk)
    
    st.markdown("---")
    
    # Charts
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Detection Timeline")
        if 'timestamp' in df.columns:
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            timeline_df = df.groupby(df['timestamp'].dt.date).size().reset_index(name='count')
            fig = px.line(timeline_df, x='timestamp', y='count', title="Detections Over Time")
            st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        st.subheader("Score Distribution")
        if 'malicious_score' in df.columns:
            fig = px.histogram(df, x='malicious_score', nbins=20, title="Malicious Score Distribution")
            st.plotly_chart(fig, use_container_width=True)
    
    st.markdown("---")
    
    # Detection table
    st.subheader("Recent Detections")
    
    # Prepare table data
    table_data = []
    for d in detections[:50]:  # Show top 50
        table_data.append({
            "ID": d.get('id'),
            "Timestamp": d.get('timestamp', '')[:19] if d.get('timestamp') else '',
            "Process": d.get('event', {}).get('process_name', 'N/A') if d.get('event') else 'N/A',
            "Score": f"{d.get('malicious_score', 0):.4f}",
            "RF Score": f"{d.get('random_forest_score', 0):.4f}",
            "LSTM Score": f"{d.get('lstm_score', 0):.4f}",
            "Malicious": "Yes" if d.get('is_malicious') else "No"
        })
    
    if table_data:
        df_table = pd.DataFrame(table_data)
        st.dataframe(df_table, use_container_width=True, height=400)
        
        # View details button
        if detections:
            selected_id = st.selectbox("View Detection Details", [d.get('id') for d in detections[:50]])
            if st.button("View Details"):
                st.session_state.selected_detection_id = selected_id
                st.rerun()
    else:
        st.info("No detections to display.")


def render_detection_details():
    """Render detailed detection view."""
    st.header("Detection Details")
    
    # Get detection ID
    detection_id = st.session_state.get('selected_detection_id')
    if not detection_id:
        detection_id = st.number_input("Enter Detection ID", min_value=1, step=1)
    
    if not detection_id:
        st.info("Enter a detection ID to view details.")
        return
    
    # Fetch detection
    detection = get_detection(detection_id)
    
    if not detection:
        st.error("Detection not found.")
        return
    
    # Display detection info
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Detection Information")
        st.write(f"**Detection ID:** {detection.get('id')}")
        st.write(f"**Timestamp:** {detection.get('timestamp', 'N/A')}")
        st.write(f"**Malicious Score:** {detection.get('malicious_score', 0):.4f}")
        st.write(f"**Random Forest Score:** {detection.get('random_forest_score', 0):.4f}")
        st.write(f"**LSTM Score:** {detection.get('lstm_score', 0):.4f}")
        st.write(f"**Is Malicious:** {'Yes' if detection.get('is_malicious') else 'No'}")
    
    with col2:
        st.subheader("Event Information")
        event = detection.get('event', {})
        st.write(f"**Process Name:** {event.get('process_name', 'N/A')}")
        st.write(f"**Command Line:**")
        st.code(event.get('command_line', 'N/A'), language='bash')
        st.write(f"**Parent Image:** {event.get('parent_image', 'N/A')}")
        st.write(f"**User:** {event.get('user', 'N/A')}")
        st.write(f"**Integrity Level:** {event.get('integrity_level', 'N/A')}")
    
    st.markdown("---")
    
    # Explanations
    st.subheader("Explanations")
    
    # OpenAI explanation
    if detection.get('openai_explanation'):
        st.write("**OpenAI Analysis:**")
        st.info(detection.get('openai_explanation'))
    
    # SHAP values
    if detection.get('shap_values'):
        st.write("**SHAP Feature Importance:**")
        shap_values = detection.get('shap_values', {})
        sorted_shap = sorted(shap_values.items(), key=lambda x: abs(x[1]), reverse=True)[:15]
        
        fig = go.Figure(data=[
            go.Bar(
                x=[v for _, v in sorted_shap],
                y=[k for k, _ in sorted_shap],
                orientation='h'
            )
        ])
        fig.update_layout(title="Top Contributing Features (SHAP)", height=400)
        st.plotly_chart(fig, use_container_width=True)
    
    # LIME explanation
    if detection.get('lime_explanation'):
        st.write("**LIME Explanation:**")
        lime_data = detection.get('lime_explanation', {})
        if isinstance(lime_data, dict):
            st.json(lime_data)
    
    st.markdown("---")
    
    # Analyst feedback
    st.subheader("Analyst Feedback")
    
    current_feedback = detection.get('analyst_feedback', '')
    current_notes = detection.get('analyst_notes', '')
    
    feedback_options = ["", "true_positive", "false_positive", "true_negative", "false_negative"]
    selected_feedback = st.selectbox("Feedback", feedback_options, index=feedback_options.index(current_feedback) if current_feedback in feedback_options else 0)
    notes = st.text_area("Notes", value=current_notes or "")
    
    if st.button("Submit Feedback"):
        if selected_feedback:
            if submit_feedback(detection.get('id'), selected_feedback, notes):
                st.success("Feedback submitted successfully!")
                st.rerun()
        else:
            st.warning("Please select a feedback option.")


def render_manual_analysis():
    """Render manual analysis page."""
    st.header("Manual Event Analysis")
    
    st.write("Submit an event for manual analysis and detection.")
    
    with st.form("event_form"):
        col1, col2 = st.columns(2)
        
        with col1:
            process_name = st.text_input("Process Name", value="powershell.exe")
            command_line = st.text_area("Command Line", height=150)
            parent_image = st.text_input("Parent Image", value="")
        
        with col2:
            user = st.text_input("User", value="")
            integrity_level = st.selectbox("Integrity Level", ["", "Low", "Medium", "High", "System"])
            event_id = st.text_input("Event ID", value="1")
        
        submitted = st.form_submit_button("Analyze Event")
        
        if submitted:
            if not command_line:
                st.error("Command line is required.")
            else:
                event_data = {
                    "event_id": event_id,
                    "timestamp": datetime.now().isoformat(),
                    "process_name": process_name,
                    "command_line": command_line,
                    "parent_image": parent_image or None,
                    "user": user or None,
                    "integrity_level": integrity_level or None
                }
                
                with st.spinner("Analyzing event..."):
                    result = submit_event(event_data)
                    
                    if result:
                        st.success("Analysis complete!")
                        st.session_state.selected_detection_id = result.get('id')
                        st.rerun()
                    else:
                        st.error("Analysis failed.")


def render_statistics():
    """Render system statistics."""
    st.header("System Statistics")
    
    stats = get_stats()
    
    if not stats:
        st.info("No statistics available.")
        return
    
    # Metrics
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Total Events", stats.get('total_events', 0))
    with col2:
        st.metric("Total Detections", stats.get('total_detections', 0))
    with col3:
        st.metric("Malicious Detections", stats.get('malicious_detections', 0))
    with col4:
        st.metric("Detection Rate", f"{stats.get('detection_rate', 0):.2f}%")
    
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("False Positives", stats.get('false_positives', 0))
    with col2:
        st.metric("False Negatives", stats.get('false_negatives', 0))
    with col3:
        st.metric("False Positive Rate", f"{stats.get('false_positive_rate', 0):.2f}%")
    
    st.markdown("---")
    
    # Charts
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Detection Metrics")
        metrics_data = {
            "Metric": ["Total Events", "Total Detections", "Malicious", "False Positives", "False Negatives"],
            "Value": [
                stats.get('total_events', 0),
                stats.get('total_detections', 0),
                stats.get('malicious_detections', 0),
                stats.get('false_positives', 0),
                stats.get('false_negatives', 0)
            ]
        }
        df_metrics = pd.DataFrame(metrics_data)
        fig = px.bar(df_metrics, x='Metric', y='Value', title="System Metrics")
        st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        st.subheader("Recent Detections")
        recent = stats.get('recent_detections', [])
        if recent:
            df_recent = pd.DataFrame(recent)
            st.dataframe(df_recent, use_container_width=True)
        else:
            st.info("No recent detections.")


if __name__ == "__main__":
    main()


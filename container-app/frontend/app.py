# Frontend Service - Web interface for rangers to view and submit wildlife sightings

from datetime import datetime
from flask import Flask, redirect, render_template, jsonify, request
import requests
import os
import logging
import time
from aws_xray_sdk.core import xray_recorder, patch_all
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize X-Ray
logger.info("Initializing X-Ray")
xray_recorder.configure(
    context_missing='LOG_ERROR',
    service='wildlife-frontend'
)
patch_all()

app = Flask(__name__, 
           static_folder='static',
           static_url_path='/wildlife/static')

logger.info("initializing xray middleware")
# Add X-Ray middleware to Flask
XRayMiddleware(app, xray_recorder)

# Simple retry mechanism: 60 attempts with 30-second delay (30 minutes total)
def connect_with_retry(connect_func, service_name, max_attempts=60, delay=30):
    logger.info(f"Connecting to {service_name} with retry logic...")
    
    for attempt in range(max_attempts):
        try:
            result = connect_func()
            logger.info(f"Successfully connected to {service_name} on attempt {attempt+1}")
            return result
        except Exception as e:
            if attempt < max_attempts - 1:
                logger.warning(f"Connection to {service_name} failed (attempt {attempt+1}/{max_attempts}): {str(e)}")
                logger.info(f"Retrying in {delay} seconds...")
                time.sleep(delay)
            else:
                logger.error(f"Failed to connect to {service_name} after {max_attempts} attempts (30 minutes)")
                raise

CACHE_HEADERS = {
    'Cache-Control': 'no-cache, no-store, must-revalidate, max-age=0',
    'Pragma': 'no-cache',
    'Expires': '0'
}

def add_cache_headers(response):
    """Add no-cache headers to response"""
    for key, value in CACHE_HEADERS.items():
        response.headers[key] = value
    return response

@app.route('/wildlife')
def wildlife_root():
    return redirect('/wildlife/')

@app.route('/wildlife/')
def index():
    logger.info("Serving index page")
    return render_template('index.html')

@app.route('/wildlife/health')
def health_check():
    logger.info("Health check requested")
    return jsonify({
        "status": "healthy",
        "service": "frontend",
        "xray": "enabled"
    }), 200

@app.route('/wildlife/api/sightings', methods=['POST'])
def report_sighting():
    try:
        logger.info("Reporting sighting")
        # Forward the form data and files to the media service
        files = None
        if 'image' in request.files:
            files = {'image': request.files['image']}
        
        response = connect_with_retry(
            lambda: requests.post(
                'http://wildlife-media.wildlife:5000/wildlife/api/sightings',
                data=request.form,
                files=files,
                timeout=30
            ),
            'Media Service (wildlife-media)'
        )
        return response.content, response.status_code, response.headers.items()
    except Exception as e:
        logger.error(f"Error reporting sighting: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/sightings', methods=['GET'])
def get_sightings():
    try:
        logger.info("Getting sightings")
        response = connect_with_retry(
            lambda: requests.get('http://wildlife-dataapi.wildlife:5000/wildlife/api/sightings', timeout=10),
            'DataAPI Service (wildlife-dataapi)'
        )
        return response.content, response.status_code, response.headers.items()
    except Exception as e:
        logger.error(f"Error getting sightings: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/images/<path:image_key>')
def get_image(image_key):
    try:
        logger.info(f"Getting image: {image_key}")
        response = connect_with_retry(
            lambda: requests.get(f'http://wildlife-media.wildlife:5000/wildlife/api/images/{image_key}', timeout=30),
            'Media Service (wildlife-media)'
        )
        return response.content, response.status_code, response.headers.items()
    except Exception as e:
        logger.error(f"Error getting image: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/gps', methods=['GET', 'POST'])
def proxy_gps():
    try:
        if request.method == 'GET':
            logger.info("Getting GPS data")
            response = connect_with_retry(
                lambda: requests.get('http://wildlife-alerts.wildlife:5000/wildlife/api/gps', timeout=10),
                'Alerts Service (wildlife-alerts)'
            )
        else:
            logger.info("Posting GPS data")
            response = connect_with_retry(
                lambda: requests.post('http://wildlife-alerts.wildlife:5000/wildlife/api/gps', json=request.json, timeout=10),
                'Alerts Service (wildlife-alerts)'
            )
        return response.content, response.status_code, response.headers.items()
    except Exception as e:
        logger.error(f"Error with GPS data: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting frontend service")
    # nosec B104: Binding to 0.0.0.0 is required for containerized apps to receive traffic from load balancers
    # semgrep:ignore python.flask.security.audit.app-run-param-config.avoid_app_run_with_bad_host
    app.run(host='0.0.0.0', port=5000)
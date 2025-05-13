# Frontend Service - Web interface for rangers to view and submit wildlife sightings

from datetime import datetime
from flask import Flask, redirect, render_template, jsonify, request
import requests
import os

app = Flask(__name__, 
           static_folder='static',
           static_url_path='/wildlife/static')

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
    return render_template('index.html')

@app.route('/wildlife/health')
def health_check():
    return jsonify({
        "status": "healthy",
        "service": "frontend"
    }), 200

@app.route('/wildlife/api/sightings', methods=['POST'])
def report_sighting():
    try:
        # Forward the form data and files to the media service
        files = None
        if 'image' in request.files:
            files = {'image': request.files['image']}
        
        response = requests.post(
            'http://wildlife-media:5000/wildlife/api/sightings',
            data=request.form,
            files=files
        )
        return response.content, response.status_code, response.headers.items()
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/sightings', methods=['GET'])
def get_sightings():
    try:
        response = requests.get('http://wildlife-data:27017/wildlife/api/sightings')
        return response.content, response.status_code, response.headers.items()
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/images/<path:image_key>')
def get_image(image_key):
    try:
        response = requests.get(f'http://wildlife-media:5000/wildlife/api/images/{image_key}')
        return response.content, response.status_code, response.headers.items()
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/gps', methods=['GET', 'POST'])
def proxy_gps():
    try:
        if request.method == 'GET':
            response = requests.get('http://wildlife-alerts:5000/wildlife/api/gps')
        else:
            response = requests.post('http://wildlife-alerts:5000/wildlife/api/gps', json=request.json)
        return response.content, response.status_code, response.headers.items()
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
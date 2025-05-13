# Media Service - Handles image upload, storage, and retrieval for wildlife sightihtings

from datetime import datetime
from io import BytesIO
import os
import uuid
import boto3
from flask import Flask, jsonify, send_file, request
from botocore.exceptions import ClientError
from dotenv import load_dotenv
from pymongo import MongoClient

app = Flask(__name__)

# Load environment variables
load_dotenv('media.env')

# Get environment variables directly
AWS_REGION = os.getenv('AWS_REGION')
BUCKET_NAME = os.getenv('BUCKET_NAME')

# Initialize S3 client
s3 = boto3.client('s3', region_name=AWS_REGION)

# Initialize MongoDB client
mongo_client = MongoClient('mongodb://wildlife-data:27017')
db = mongo_client.wildlife_db

# Constants
ALLOWED_IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif'}

def handle_image_upload(file):
    """Handle image upload to S3"""
    if not file.filename:
        return None
    
    try:
        file_extension = os.path.splitext(file.filename)[1]
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        filename = f"sightings/{datetime.now().strftime('%Y%m%d')}/{unique_filename}"
        
        s3.upload_fileobj(
            file,
            BUCKET_NAME,
            filename,
            ExtraArgs={'ContentType': file.content_type}
        )
        return filename
    except Exception as e:
        print(f"Error uploading image: {str(e)}")
        return None

@app.route('/wildlife/api/images/<path:image_key>')
def get_image(image_key):
    # Validate image key
    if not image_key or '..' in image_key:
        return jsonify({"error": "Invalid image key"}), 400

    if not any(image_key.lower().endswith(ext) for ext in ALLOWED_IMAGE_EXTENSIONS):
        return jsonify({"error": "Invalid file type"}), 400

    try:
        response = s3.get_object(Bucket=BUCKET_NAME, Key=image_key)
        return send_file(
            BytesIO(response['Body'].read()),
            mimetype=response.get('ContentType', 'image/jpeg'),
            as_attachment=False
        )
    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')
        if error_code == 'NoSuchKey':
            return jsonify({"error": "Image not found"}), 404
        return jsonify({"error": "Failed to retrieve image"}), 500
    except Exception as e:
        return jsonify({"error": "Internal server error"}), 500

@app.route('/wildlife/api/sightings', methods=['POST'])
def report_sighting():
    if not request.form:
        return jsonify({"error": "No form data received"}), 400
            
    try:
        data = request.form.to_dict()
        
        # Convert coordinates to float
        for coord in ['latitude', 'longitude']:
            if coord in data:
                try:
                    data[coord] = float(data[coord])
                except ValueError:
                    return jsonify({"error": f"Invalid {coord}"}), 400
        
        # Add timestamp
        data['timestamp'] = datetime.utcnow()
        
        # Handle image upload
        if 'image' in request.files:
            image_url = handle_image_upload(request.files['image'])
            if image_url:
                data['image_url'] = image_url
        
        # Store in MongoDB
        db.sightings.insert_one(data)
        
        return jsonify({"message": "Sighting reported successfully"}), 200

    except Exception as e:
        print(f"Error in report_sighting: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/sightings', methods=['GET'])
def get_sightings():
    try:
        sightings = list(db.sightings.find({}, {'_id': False}))
        return jsonify(sightings), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
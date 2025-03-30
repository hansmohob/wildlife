from datetime import datetime
from io import BytesIO
import os
import uuid

import boto3
from flask import Flask, jsonify, send_file, request
from botocore.exceptions import ClientError

app = Flask(__name__)

# Environment variables
ENV_VARS = {
    'PREFIX_CODE': os.getenv('PREFIX_CODE'),
    'AWS_ACCOUNT_ID': os.getenv('AWS_ACCOUNT_ID'),
    'BUCKET_NAME': os.getenv('BUCKET_NAME'),
    'AWS_REGION': os.getenv('AWS_REGION')
}

if not all(ENV_VARS.values()):
    raise ValueError("Missing required environment variables: " + 
                    ", ".join(k for k, v in ENV_VARS.items() if not v))

# Initialize S3 client
s3 = boto3.client('s3', region_name=ENV_VARS['AWS_REGION'])

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
            ENV_VARS['BUCKET_NAME'],
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
        return jsonify({"error": "Invalid file type"}), 4, 400

    try:
        response = s3.get_object(Bucket=ENV_VARS['BUCKET_NAME'], Key=image_key)
        return send_file(
            BytesIO(response['Body'].read()),
            mimetyetype=response.get('ContentType', 'image/jpeg'),
            as_attachment=False
        )
    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')
        if error_code == 'NoSuchKey':
            return jsonify({"error": "Image not found"}), 404
        return jsonify({"error": "Failed to retrieve image"}), 500
    except Exception as e:
        return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
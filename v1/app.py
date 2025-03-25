from flask import Flask, render_template, request, jsonify, redirect, send_from_directory
from datetime import datetime, timedelta
import boto3
from botocore.exceptions import ClientError
import os
from pymongo import MongoClient
from werkzeug.utils import secure_filename
import uuid
from flask import send_file, jsonify
from io import BytesIO
from botocore.exceptions import ClientError

app = Flask(__name__, 
           static_folder='static',
           static_url_path='/wildlife/static')

# Initialize AWS client
s3 = boto3.client('s3', region_name=os.getenv('AWS_REGION'))

# Get environment variables
PREFIX_CODE = os.getenv('PREFIX_CODE')
AWS_ACCOUNT_ID = os.getenv('AWS_ACCOUNT_ID')
BUCKET_NAME = os.getenv('BUCKET_NAME')
AWS_REGION = os.getenv('AWS_REGION')

if not all([PREFIX_CODE, AWS_ACCOUNT_ID, BUCKET_NAME, AWS_REGION]):
    raise ValueError("Missing required environment variables. Please set PREFIX_CODE, AWS_ACCOUNT_ID, BUCKET_NAME, and AWS_REGION")

# Initialize MongoDB client
client = MongoClient('mongodb://localhost:27017/')
db = client.wildlife_db

@app.route('/wildlife')
def wildlife_root():
    return redirect('/wildlife/')

@app.route('/wildlife/')
def index():
    return render_template('index.html')

@app.route('/wildlife/api/sightings', methods=['POST'])
def report_sighting():
    print("\n=== Starting new sighting report ===")
    try:
        print("POST request received")
        print("Form data:", request.form)
        print("Files:", request.files)
        
        if not request.form:
            print("No form data received")
            return jsonify({"error": "No form data received"}), 400
            
        data = request.form.to_dict()
        print("Converted form data:", data)
        
        # Convert latitude and longitude to float
        try:
            if 'latitude' in data:
                data['latitude'] = float(data['latitude'])
            if 'longitude' in data:
                data['longitude'] = float(data['longitude'])
        except ValueError:
            return jsonify({"error": "Invalid coordinates"}), 400
        
        # Add timestamp
        data['timestamp'] = datetime.utcnow()
        print("Added timestamp:", data['timestamp'])
        
        # Handle image upload if present
        if 'image' in request.files:
            file = request.files['image']
            print("Image file received:", file.filename)
            
            if file.filename:
                try:
                    file_extension = os.path.splitext(file.filename)[1]
                    unique_filename = f"{uuid.uuid4()}{file_extension}"
                    filename = f"sightings/{datetime.now().strftime('%Y%m%d')}/{unique_filename}"
                    print("Generated filename:", filename)
                    print("Attempting S3 upload to bucket:", BUCKET_NAME)
                    
                    if not BUCKET_NAME:
                        raise ValueError("BUCKET_NAME environment variable not set")
                    
                    s3.upload_fileobj(
                        file,
                        BUCKET_NAME,
                        filename,
                        ExtraArgs={'ContentType': file.content_type}
                    )
                    print("S3 upload successful")
                    data['image_url'] = filename
                except Exception as s3_error:
                    print("S3 upload error details:")
                    print("Error type:", type(s3_error))
                    print("Error message:", str(s3_error))
                    import traceback
                    print("Traceback:", traceback.format_exc())
                    print("Continuing without image...")
        
        print("Attempting MongoDB insert with data:", data)
        # Store in MongoDB
        result = db.sightings.insert_one(data)
        print("MongoDB insert successful, ID:", result.inserted_id)
        
        # Create response with no-cache headers
        response = jsonify({"message": "Sighting reported successfully"})
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = '0'
        return response, 200

    except Exception as e:
        print("\n=== Error in report_sighting ===")
        print("Error type:", type(e))
        print("Error message:", str(e))
        import traceback
        print("Full traceback:", traceback.format_exc())
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/sightings', methods=['GET'])
def get_sightings():
    try:
        print("Getting sightings from MongoDB")
        sightings = list(db.sightings.find({}, {'_id': False}))
        response = jsonify(sightings)
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = '0'
        return response, 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/images/<path:image_key>')
def get_image(image_key):
    try:
        # Basic validation of image key
        if not image_key or '..' in image_key:  # Prevent path traversal
            return jsonify({"error": "Invalid image key"}), 400

        # Check file extension
        allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif'}
        if not any(image_key.lower().endswith(ext) for ext in allowed_extensions):
            return jsonify({"error": "Invalid file type"}), 400

        try:
            # Get the image from S3
            response = s3.get_object(Bucket=BUCKET_NAME, Key=image_key)
            image_data = response['Body'].read()
            
            # Create a BytesIO object
            image_stream = BytesIO(image_data)
            
            # Get content type or default to jpeg
            content_type = response.get('ContentType', 'image/jpeg')
            
            return send_file(
                image_stream,
                mimetype=content_type,
                as_attachment=False
            )

        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            if error_code == 'NoSuchKey':
                return jsonify({"error": "Image not found"}), 404
            else:
                print(f"S3 error: {str(e)}")  # Log the error
                return jsonify({"error": "Failed to retrieve image"}), 500

    except Exception as e:
        print(f"Unexpected error: {str(e)}")  # Log the error
        return jsonify({"error": "Internal server error"}), 500

@app.route('/wildlife/api/gps', methods=['POST'])
def receive_gps():
    try:
        data = request.json
        # Add timestamp
        data['timestamp'] = datetime.utcnow()
        # Store in MongoDB in a new collection
        db.gps_tracking.insert_one(data)
        return jsonify({"message": "GPS data received"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/gps', methods=['GET'])
def get_gps_data():
    try:
        cutoff = datetime.utcnow() - timedelta(hours=24)
        gps_data = list(db.gps_tracking.find(
            {"timestamp": {"$gt": cutoff}}, 
            {'_id': False}
        ))
        response = jsonify(gps_data)
        # Add cache control headers
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, max-age=0'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = '0'
        return response, 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
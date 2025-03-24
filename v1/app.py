from flask import Flask, render_template, request, jsonify, redirect
from datetime import datetime
import boto3
from botocore.exceptions import ClientError
import os
from pymongo import MongoClient
from werkzeug.utils import secure_filename
import uuid
from flask import send_file, jsonify
from io import BytesIO
from botocore.exceptions import ClientError

app = Flask(__name__)

# Initialize AWS S3 client
s3 = boto3.client('s3')
BUCKET_NAME = os.getenv('BUCKET_NAME')  

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
                    # Continue without image if S3 upload fails
                    print("Continuing without image...")
        
        print("Attempting MongoDB insert with data:", data)
        # Store in MongoDB
        result = db.sightings.insert_one(data)
        print("MongoDB insert successful, ID:", result.inserted_id)
        
        return jsonify({"message": "Sighting reported successfully"}), 200
    except Exception as e:
        print("\n=== Error in report_sighting ===")
        print("Error type:", type(e))
        print("Error message:", str(e))
        import traceback
        print("Full traceback:", traceback.format_exc())
        return jsonify({"error": str(e)}), 500
        
        # Store in MongoDB
        db.sightings.insert_one(data)
        
        return jsonify({"message": "Sighting reported successfully"}), 200
    except Exception as e:
        print("Final error:", str(e))
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/sightings', methods=['GET'])
def get_sightings():
    try:
        sightings = list(db.sightings.find({}, {'_id': False}))
        return jsonify(sightings), 200
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
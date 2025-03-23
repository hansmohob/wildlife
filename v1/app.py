from flask import Flask, render_template, request, jsonify, redirect
from datetime import datetime
import boto3
from botocore.exceptions import ClientError
import os
from pymongo import MongoClient
from werkzeug.utils import secure_filename

app = Flask(__name__)

# Initialize AWS S3 client
s3 = boto3.client('s3')
BUCKET_NAME = os.getenv('BUCKET_NAME')  

# Initialize MongoDB client
client = MongoClient('mongodb://localhost:27017/')
db = client.wildlife_db

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/sightings', methods=['POST'])
def report_sighting():
    try:
        data = request.form.to_dict()
        data['timestamp'] = datetime.utcnow()
        
        # Handle image upload if present
        if 'image' in request.files:
            file = request.files['image']
            print("Got file:", file.filename)
            if file.filename:
                # Create unique filename with timestamp
                timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
                filename = f"sightings/{timestamp}-{secure_filename(file.filename)}"
                print("Attempting S3 upload to bucket:", BUCKET_NAME)
                print("With filename:", filename)
                
                try:
                    # Upload to S3
                    s3.upload_fileobj(
                           file,
                        BUCKET_NAME,
                        filename,
                        ExtraArgs={'ContentType': file.content_type}
                    )
                    print("S3 upload successful")
                    data['image_url'] = filename
                except Exception as s3_error:
                    print("S3 upload failed with error:", str(s3_error))
                    print("Error type:", type(s3_error))
                    import traceback
                    print("Traceback:", traceback.format_exc())
                    raise
        
        # Store in MongoDB
        db.sightings.insert_one(data)
        
        return jsonify({"message": "Sighting reported successfully"}), 200
    except Exception as e:
        print("Final error:", str(e))
        return jsonify({"error": str(e)}), 500

@app.route('/api/sightings', methods=['GET'])
def get_sightings():
    try:
        sightings = list(db.sightings.find({}, {'_id': False}))
        return jsonify(sightings), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/images/<path:image_key>')
def get_image(image_key):
    try:
        # Generate a presigned URL for the S3 object
        url = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': BUCKET_NAME, 'Key': image_key},
            ExpiresIn=3600
        )
        return redirect(url)
    except ClientError as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
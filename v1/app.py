from flask import Flask, render_template, request, jsonify
from datetime import datetime
import boto3
import os
from pymongo import MongoClient

app = Flask(__name__)

# Initialize AWS S3 client
s3 = boto3.client('s3')

# Initialize MongoDB client
client = MongoClient('mongodb://localhost:27017/')
db = client.wildlife_db

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/sightings', methods=['POST'])
def report_sighting():
    try:
        data = request.json
        data['timestamp'] = datetime.utcnow()
        
        # Store in MongoDB
        db.sightings.insert_one(data)
        
        return jsonify({"message": "Sighting reported successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/sightings', methods=['GET'])
def get_sightings():
    try:
        sightings = list(db.sightings.find({}, {'_id': False}))
        return jsonify(sightings), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

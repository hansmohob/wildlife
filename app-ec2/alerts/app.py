from datetime import datetime, timedelta
import os

from flask import Flask, jsonify, request
from pymongo import MongoClient

app = Flask(__name__)

# Environment variables
ENV_VARS = {
    'PREFIX_CODE': os.getenv('PREFIX_CODE'),
    'AWS_ACCOUNT_ID': os.getenv('AWS_ACCOUNT_ID'),
    'BUCKET_NAME': os.getenv('BUCKET_NAME'),
    'AWS_REGION': os.getenv('AWS_REGION'),
    'MONGODB_URI': os.getenv('MONGODB_URI')
}

if not all(ENV_VARS.values()):
    raise ValueError("Missing required environment variables: " + 
                    ", ".join(k for k, v in ENV_VARS.items() if not v))

# Initialize MongoDB client
mongo_client = MongoClient(ENV_VARS['MONGODB_URI'])
db = mongo_client.wildlife_db

@app.route('/wildlife/api/gps', methods=['POST'])
def receive_gps():
    try:
        data = request.json
        data['timestamp'] = datetime.utcnow()
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
        return jsonify(gps_data), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
from datetime import datetime, timedelta
import os
from flask import Flask, jsonify, request
from pymongo import MongoClient
from dotenv import load_dotenv

app = Flask(__name__)

# Environment variables
load_dotenv('wildlife.env')

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
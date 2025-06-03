# Data API Service - faciliates frontend access to data service

from flask import Flask, jsonify, request
from pymongo import MongoClient
import logging
from aws_xray_sdk.core import xray_recorder, patch_all
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize X-Ray
logger.info("Initializing X-Ray")
xray_recorder.configure(
    context_missing='LOG_ERROR',
    service='wildlife-data'
)
patch_all()

# Disable OTEL metrics export that's causing errors
import os
os.environ["OTEL_SDK_DISABLED"] = "true"

app = Flask(__name__)

logger.info("initializing xray middleware")
# Add X-Ray middleware to Flask
XRayMiddleware(app, xray_recorder)

# Initialize MongoDB client
logger.info("Starting MongoDB")
client = MongoClient('mongodb://wildlife-data.wildlife:27017')
db = client.wildlife_db

@app.route('/wildlife/health')
def health_check():
    logger.info("Health check requested")
    return jsonify({
        "status": "healthy",
        "service": "data"
    }), 200

@app.route('/wildlife/api/sightings', methods=['GET'])
def get_sightings():
    try:
        logger.info("Getting sightings from MongoDB")
        sightings = list(db.sightings.find({}, {'_id': False}))
        return jsonify(sightings), 200
    except Exception as e:
        logger.error(f"Error getting sightings: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/wildlife/api/sightings/<sighting_id>', methods=['GET'])
def get_sighting(sighting_id):
    try:
        logger.info(f"Getting sighting {sighting_id}")
        sighting = db.sightings.find_one({"id": sighting_id}, {'_id': False})
        if sighting:
            return jsonify(sighting), 200
        else:
            return jsonify({"error": "Sighting not found"}), 404
    except Exception as e:
        logger.error(f"Error getting sighting: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    logger.info("Starting data service")
    app.run(host='0.0.0.0', port=5000)
# Wildlife Monitoring Application - EC2 Version

This is a monolithic Wildlife Monitoring Application that runs on Amazon EC2.

## Components

**Single Application (`app.py`)**: A monolithic Flask application that handles:
- Web interface
- Main API endpoints
- Data API endpoints

## Running the Application

The application is configured to run as a systemd service. The `wildlife-app.service` file defines how the application should be started.

To manually start the application:

```bash
python app.py
```

This will start the application on port 5000.

## API Endpoints

### Main Application Endpoints

- `GET /wildlife/`: Main web interface
- `GET /wildlife/api/sightings`: Get all wildlife sightings
- `POST /wildlife/api/sightings`: Report a new wildlife sighting
- `GET /wildlife/api/images/<path>`: Get an image from S3
- `GET /wildlife/api/gps`: Get GPS tracking data
- `POST /wildlife/api/gps`: Submit GPS tracking data

### Data API Endpoints (Same application, different routes)

- `GET /wildlife/api/data/health`: Health check endpoint
- `GET /wildlife/api/data/sightings`: Get all wildlife sightings
- `GET /wildlife/api/data/sightings/<id>`: Get a specific wildlife sighting
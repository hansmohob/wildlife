# wildlife
here be dragons

# Wildlife Workshop - ECS Deployment

Interactive menu-driven script for deploying a containerized wildlife tracking application on AWS ECS.

## 🚀 Quick Start

### Interactive Mode
```bash
./real-menu-start.sh
```

### Automation Mode
```bash
./real-menu-start.sh --ci --command full_build
./real-menu-start.sh --ci --command full_cleanup
```

## 📋 Menu Structure

### BUILD (1-11)
Build and deploy the complete application infrastructure

### OPERATE (12-13)
- **Configure Service Auto Scaling** - Scale containers based on CPU
- **Configure Capacity Auto Scaling** - Scale EC2 instances automatically

### QUICK ACTIONS (14-18)
- **Show Application URL** - Access your deployed app
- **Run Service Scaling Test** - Test container scaling with k6 load test
- **Run Capacity Scaling Test** - Test infrastructure scaling
- **Full Build** / **Full Cleanup** - One-click operations

### CLEANUP (19-27)
Remove all AWS resources

## 🔧 Prerequisites

- AWS CLI configured
- Docker installed and running
- k6 installed (for scaling tests)

## 📁 Files

- `real-menu-start.sh` - Production script
- `menu-start.sh` - Development version
- `loadtest-service-scaling.js` - k6 script for service scaling
- `loadtest-capacity-scaling.js` - k6 script for capacity scaling

---

**Ready to learn AWS containerization? Run `./real-menu-start.sh` and start building!** 🚀

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
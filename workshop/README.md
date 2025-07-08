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
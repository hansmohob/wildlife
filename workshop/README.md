# Wildlife Workshop - ECS Deployment Script

An interactive menu-driven script for deploying a containerized wildlife tracking application on AWS ECS. This script serves both as an educational tool for learning AWS CLI commands and as an automation tool for CI/CD pipelines.

## 🎯 Purpose

This script demonstrates how to build and deploy a complete microservices application on AWS using:
- **Amazon ECS** (Elastic Container Service) with EC2 capacity providers
- **Amazon ECR** (Elastic Container Registry) for container images
- **Application Load Balancer** for traffic distribution
- **Amazon EFS** (Elastic File System) for persistent storage
- **VPC Endpoints** for secure ECR access
- **Auto Scaling Groups** for container instance management

## 🏗️ Architecture

The wildlife application consists of 5 microservices:
- **Frontend** - Web interface (React)
- **DataAPI** - REST API for data access
- **DataDB** - MongoDB database service
- **Media** - Image upload and processing
- **Alerts** - Notification service

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Docker installed and running
- EC2 instance with sufficient resources
- VPC and networking infrastructure pre-configured

## 🚀 Usage

### Interactive Mode (Educational)

Run the script interactively to learn AWS CLI commands step by step:

```bash
./real-menu-start.sh
```

This mode provides:
- ✅ **Clear AWS CLI command documentation** with inline comments
- ✅ **Step-by-step execution** with explanations
- ✅ **Persistent state tracking** across sessions
- ✅ **Execution counters** to track command usage
- ✅ **Interactive confirmations** for safety

### Automation Mode (CI/CD)

Run the script non-interactively for automated testing and deployment:

#### Full Setup Only
```bash
./real-menu-start.sh --ci --command full_setup
```

#### Full Cleanup Only
```bash
./real-menu-start.sh --ci --command full_cleanup
```

#### Complete Deployment Test (Setup + Cleanup)
```bash
./real-menu-start.sh --ci --command test_deployment
```

#### Environment Variable Approach
```bash
export CI_MODE=true
./real-menu-start.sh --command full_setup
```

## 🎓 Educational Features

### AWS CLI Command Documentation

Each function includes clear comments highlighting the AWS CLI commands being used:

```bash
create_ecr_repos() {
    echo -e "${GREEN}Creating ECR Repositories...${NC}"
    
    # AWS CLI COMMANDS: Create ECR repositories for each container image
    aws ecr create-repository --repository-name wildlife/alerts
    aws ecr create-repository --repository-name wildlife/datadb
    # ... more commands
}
```

### Learning Objectives

By using this script, you'll learn how to:
- Create and manage ECR repositories
- Build and push container images
- Set up VPC endpoints for secure access
- Deploy ECS clusters with capacity providers
- Configure Application Load Balancers
- Manage ECS services and task definitions
- Implement persistent storage with EFS
- Clean up AWS resources properly

## 📊 Menu Structure

### Setup Commands (1-11)
1. **Create ECR Repositories** - Set up container registries
2. **Build Container Images** - Build Docker images locally
3. **Push Images to ECR** - Upload images to AWS
4. **Setup VPC Endpoints** - Configure secure ECR access
5. **Deploy ECS Cluster** - Create cluster with auto scaling
6. **Register Task Definitions** - Define container specifications
7. **Create Load Balancer** - Set up ALB with target groups
8. **Create ECS Services** - Deploy microservices
9. **Fix Image Upload** - Configure S3 permissions
10. **Fix GPS Data** - Configure Lambda integration
11. **Create EFS Storage** - Set up persistent file system

### Cleanup Commands (12-20)
12. **Delete ECS Services** - Remove running services
13. **Delete Load Balancer** - Remove ALB and target groups
14. **Delete ECS Cluster** - Remove cluster and capacity providers
15. **Delete Auto Scaling Group** - Remove EC2 instances
16. **Delete Task Definitions** - Deregister task definitions
17. **Delete VPC Endpoints** - Remove VPC endpoints
18. **Delete EFS Storage** - Remove file systems
19. **Delete ECR Repositories** - Remove container registries
20. **Clean Docker Images** - Remove local images

### Quick Actions (21-24)
21. **Full Setup** - Run all setup commands in sequence
22. **Check Deployment Status** - View current infrastructure state
23. **Show Application URL** - Display application access URL
24. **Full Cleanup** - Run all cleanup commands in sequence

## 💾 Persistent State Management

The script maintains state across sessions using `/home/ec2-user/workspace/my-workspace/menu-vars.env`:

### Infrastructure Variables
- `EFS_ID` - EFS file system identifier
- `ALB_ARN` - Application Load Balancer ARN
- `ALB_DNS` - Load balancer DNS name
- `TG_ARN` - Target group ARN
- `ASG_ARN` - Auto Scaling Group ARN

### Execution Counters
- Tracks how many times each command has been executed
- Displays execution count in menu (e.g., "Create ECR Repositories (2x)")
- Persists across terminal sessions and reboots

## 🔧 CI/CD Pipeline Integration

### GitHub Actions Example
```yaml
name: Wildlife Deployment Test
on: [push, pull_request]

jobs:
  test-deployment:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v3
      - name: Test Full Deployment
        run: |
          cd workshop
          ./real-menu-start.sh --ci --command test_deployment
```

### Jenkins Pipeline Example
```groovy
pipeline {
    agent { label 'workshop-test-server' }
    stages {
        stage('Test Deployment') {
            steps {
                sh '''
                    cd workshop
                    ./real-menu-start.sh --ci --command test_deployment
                '''
            }
        }
    }
}
```

### AWS CodeBuild Example
```yaml
version: 0.2
phases:
  build:
    commands:
      - cd workshop
      - ./real-menu-start.sh --ci --command test_deployment
```

## 🛡️ Safety Features

- **Confirmation prompts** for destructive operations
- **Resource existence checks** before deletion
- **Graceful error handling** for missing resources
- **State persistence** to resume interrupted operations
- **Clean separation** between setup and cleanup operations

## 🔍 Troubleshooting

### Common Issues

1. **Docker not running**: Ensure Docker daemon is started
2. **AWS permissions**: Verify IAM permissions for ECS, ECR, EC2, ELB
3. **VPC configuration**: Ensure subnets and security groups exist
4. **Resource limits**: Check AWS service limits for your account

### Debug Mode

For verbose output, you can modify the script to add debug information:
```bash
set -x  # Add at the top of functions for detailed execution logs
```

## 📁 File Structure

```
workshop/
├── real-menu-start.sh          # Main deployment script
├── menu-start.sh              # Working/development version
├── ec2_user_data.sh           # EC2 instance initialization
├── README.md                  # This documentation
└── ../menu-vars.env           # Persistent state file (auto-created)
```

## 🤝 Contributing

This script is designed for educational purposes. When making changes:
1. Preserve AWS CLI command visibility with clear comments
2. Maintain the educational structure and flow
3. Test both interactive and automation modes
4. Update documentation for any new features

## 📝 License

This educational workshop script is provided as-is for learning AWS containerization concepts.

---

**Happy Learning! 🎓**

For questions or issues, refer to the AWS documentation or workshop materials.
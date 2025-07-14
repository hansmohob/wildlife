#!/bin/bash

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables file for persistence
VARS_FILE="/home/ec2-user/workspace/my-workspace/menu-vars.env"

# Execution tracking
declare -A EXECUTION_COUNT=()

# CI/Automation mode
CI_MODE=${CI_MODE:-false}
CI_COMMAND=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ci|--auto)
            CI_MODE=true
            shift
            ;;
        --command)
            CI_COMMAND="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# =============================================================================
# PERSISTENT STORAGE FUNCTIONS
# =============================================================================

create_vars_file() {
    if [ ! -f "$VARS_FILE" ]; then
        cat > "$VARS_FILE" << 'EOF'
# Wildlife Application Variables
EFS_ID=""
ALB_ARN=""
ALB_DNS=""
TG_ARN=""
ASG_ARN=""

# Execution Counters
EXEC_create_ecr_repos=0
EXEC_build_images=0
EXEC_push_images=0
EXEC_setup_vpc_endpoints=0
EXEC_deploy_ecs_cluster=0
EXEC_register_task_definitions=0
EXEC_create_load_balancer=0
EXEC_create_ecs_services=0
EXEC_fix_image_upload=0
EXEC_fix_gps_data=0
EXEC_create_efs_storage=0
EXEC_configure_service_scaling=0
EXEC_configure_capacity_scaling=0
EXEC_cleanup_services=0
EXEC_cleanup_load_balancer=0
EXEC_cleanup_cluster=0
EXEC_cleanup_asg=0
EXEC_cleanup_task_definitions=0
EXEC_cleanup_vpc_endpoints=0
EXEC_cleanup_efs=0
EXEC_cleanup_ecr=0
EXEC_cleanup_docker=0
EXEC_full_build=0
EXEC_show_app_url=0
EXEC_run_service_scaling_test=0
EXEC_run_capacity_scaling_test=0
EXEC_full_cleanup=0
EXEC_deploy_adot=0
EOF
    fi
}

load_variables() {
    create_vars_file
    source "$VARS_FILE" 2>/dev/null || true
    
    # Load execution counts into EXECUTION_COUNT array
    for func in create_ecr_repos build_images push_images setup_vpc_endpoints deploy_ecs_cluster register_task_definitions create_load_balancer create_ecs_services fix_image_upload fix_gps_data create_efs_storage configure_service_scaling configure_capacity_scaling cleanup_services cleanup_load_balancer cleanup_cluster cleanup_asg cleanup_task_definitions cleanup_vpc_endpoints cleanup_efs cleanup_ecr cleanup_docker full_build show_app_url run_service_scaling_test run_capacity_scaling_test full_cleanup deploy_adot; do
        local exec_var="EXEC_${func}"
        EXECUTION_COUNT["$func"]=${!exec_var:-0}
    done
}

save_variable() {
    local var_name="$1"
    local var_value="$2"
    create_vars_file
    # Use | as delimiter instead of / to handle ARNs with forward slashes
    sed -i "s|^${var_name}=.*|${var_name}=\"${var_value}\"|" "$VARS_FILE"
}

save_execution_count() {
    local func_name="$1"
    local count="${EXECUTION_COUNT[$func_name]}"
    local exec_var="EXEC_${func_name}"
    save_variable "$exec_var" "$count"
}

show_header() {
    clear
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${PURPLE}                    AWS 101 - Containers                         ${NC}"
    echo -e "${PURPLE}                    Wildlife Ranger Tool!                        ${NC}"
    echo -e "${PURPLE}================================================================${NC}"
    echo ""
}

# =============================================================================
# MENU CONFIGURATION - JUST ADD FUNCTIONS HERE!
# =============================================================================
# Format: "FUNCTION_NAME|DISPLAY_TEXT|SECTION"
# Sections: BUILD, OPERATE, CLEANUP, QUICK, ADVANCED
# The menu will auto-number and auto-discover these functions

declare -a MENU_ITEMS=(
    # BUILD COMMANDS
    "create_ecr_repos|Create ECR Repositories|BUILD"
    "build_images|Build Container Images|BUILD"
    "push_images|Push Images to ECR|BUILD"
    "setup_vpc_endpoints|Setup VPC Endpoints|BUILD"
    "deploy_ecs_cluster|Deploy ECS Cluster|BUILD"
    "register_task_definitions|Register Task Definitions|BUILD"
    "create_load_balancer|Create Load Balancer|BUILD"
    "create_ecs_services|Create ECS Services|BUILD"
    "fix_image_upload|Fix Image Upload|BUILD"
    "fix_gps_data|Fix GPS Data|BUILD"
    "create_efs_storage|Create EFS Storage|BUILD"

    # OPERATE COMMANDS
    "configure_service_scaling|Configure Service Auto Scaling|OPERATE"
    "run_service_scaling_test|Run Service Scaling Test|OPERATE"
    "configure_capacity_scaling|Configure Capacity Auto Scaling|OPERATE"
    "run_capacity_scaling_test|Run Capacity Scaling Test|OPERATE"
    
    # QUICK ACTIONS
    "show_app_url|Show Application URL|QUICK"
    "full_build|Full Build (All Build Commands)|QUICK"
    "full_cleanup|Full Cleanup (All Cleanup Commands)|QUICK"
    
    # CLEANUP COMMANDS
    "cleanup_services|Delete ECS Services|CLEANUP"
    "cleanup_load_balancer|Delete Load Balancer|CLEANUP"
    "cleanup_cluster|Delete ECS Cluster|CLEANUP"
    "cleanup_asg|Delete Auto Scaling Group|CLEANUP"
    "cleanup_task_definitions|Delete Task Definitions|CLEANUP"
    "cleanup_vpc_endpoints|Delete VPC Endpoints|CLEANUP"
    "cleanup_efs|Delete EFS Storage|CLEANUP"
    "cleanup_ecr|Delete ECR Repositories|CLEANUP"
    "cleanup_docker|Clean Docker Images|CLEANUP"

    # ADVANCED FEATURES
    "deploy_adot|Deploy ADOT (OpenTelemetry)|ADVANCED"
)

show_menu() {
    declare -A menu_numbers
    local counter=1
    local current_section=""
    
    # Build menu with auto-numbering (zero-padded)
    for item in "${MENU_ITEMS[@]}"; do
        IFS='|' read -r func_name display_text section <<< "$item"
        
        # Show section header if changed
        if [ "$section" != "$current_section" ]; then
            echo ""
            case $section in
                "BUILD") echo -e "${CYAN}BUILD COMMANDS:${NC}" ;;
                "OPERATE") echo -e "${GREEN}OPERATE COMMANDS:${NC}" ;;
                "CLEANUP") echo -e "${RED}CLEANUP COMMANDS:${NC}" ;;
                "QUICK") echo -e "${YELLOW}QUICK ACTIONS:${NC}" ;;
                "ADVANCED") echo -e "${BLUE}ADVANCED FEATURES:${NC}" ;;
            esac
            current_section="$section"
        fi
        
        # Store mapping and display menu item with zero-padded numbers
        local padded_number=$(printf "%02d" $counter)
        menu_numbers[$counter]="$func_name"
        
        # Add execution counter display
        local count_display=""
        if [[ ${EXECUTION_COUNT["$func_name"]} -gt 0 ]]; then
            count_display=" ${YELLOW}(${EXECUTION_COUNT["$func_name"]}x)${NC}"
        fi
        echo -e "  ${GREEN}$padded_number)${NC} $display_text$count_display"
        ((counter++))
    done
    
    echo ""
    echo -e "${BLUE}00)${NC} Exit"
    echo ""
    echo -n -e "${CYAN}Enter your choice: ${NC}"
    
    # Export the mapping for execute_command to use
    declare -p menu_numbers > /tmp/menu_mapping.sh
}

execute_command() {
    local choice=$1
    
    # Load the menu mapping
    source /tmp/menu_mapping.sh 2>/dev/null
    
    # Handle exit (accept both 0 and 00)
    if [ "$choice" = "0" ] || [ "$choice" = "00" ]; then
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
    fi
    
    # Convert input to number (removes leading zeros) - handle non-numeric input
    local numeric_choice
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        numeric_choice=$((10#$choice))
    else
        numeric_choice=0
    fi
    
    # Get function name from mapping
    local func_name="${menu_numbers[$numeric_choice]}"
    
    if [ -z "$func_name" ]; then
        echo -e "${RED}Invalid option: $choice${NC}"
        return 1
    fi
    
    # Check if function exists and execute it
    if declare -f "$func_name" > /dev/null; then
        echo -e "${YELLOW}Executing: $func_name${NC}"
        echo ""
        $func_name
        
        # Increment execution counter
        ((EXECUTION_COUNT["$func_name"]++))
        
        # Save execution count persistently
        save_execution_count "$func_name"
    else
        echo -e "${YELLOW}Function '$func_name' not implemented yet${NC}"
        echo "Add the function '$func_name()' to this script to implement this feature."
    fi
    
    return 0
}

# =============================================================================
# BUILD COMMANDS
# =============================================================================

create_ecr_repos() {
    echo -e "${GREEN}Creating ECR Repositories...${NC}"
    
    # AWS CLI COMMANDS: Create ECR repositories for each container image
    aws ecr create-repository --repository-name REPLACE_PREFIX_CODE/alerts
    aws ecr create-repository --repository-name REPLACE_PREFIX_CODE/datadb
    aws ecr create-repository --repository-name REPLACE_PREFIX_CODE/dataapi
    aws ecr create-repository --repository-name REPLACE_PREFIX_CODE/frontend 
    aws ecr create-repository --repository-name REPLACE_PREFIX_CODE/media
    
    echo -e "${GREEN}✅ ECR Repositories created${NC}"
}

build_images() {
    echo -e "${GREEN}Building Container Images...${NC}"
    
    # DOCKER COMMANDS: Build container images for each microservice
    cd /home/ec2-user/workspace/my-workspace/container-app && \
        docker build -t REPLACE_PREFIX_CODE/alerts ./alerts && \
        docker build -t REPLACE_PREFIX_CODE/datadb ./datadb && \
        docker build -t REPLACE_PREFIX_CODE/dataapi ./dataapi && \
        docker build -t REPLACE_PREFIX_CODE/frontend ./frontend && \
        cp ../terraform/ignoreme.txt ./media/dockerfile && \
        docker build -t REPLACE_PREFIX_CODE/media ./media && \
        docker image ls | grep REPLACE_PREFIX_CODE
        
    echo -e "${GREEN}✅ Container images built${NC}"
}

push_images() {
    echo -e "${GREEN}Pushing Images to ECR...${NC}"
    
    # AWS CLI COMMANDS: Login to ECR and push container images
    aws ecr get-login-password --region REPLACE_AWS_REGION | docker login --username AWS --password-stdin REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com
    docker tag REPLACE_PREFIX_CODE/alerts REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/alerts:latest
    docker tag REPLACE_PREFIX_CODE/datadb REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/datadb:latest
    docker tag REPLACE_PREFIX_CODE/dataapi REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/dataapi:latest
    docker tag REPLACE_PREFIX_CODE/frontend REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/frontend:latest
    docker tag REPLACE_PREFIX_CODE/media REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/media:latest
    stdbuf -oL docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/alerts:latest
    stdbuf -oL docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/datadb:latest
    stdbuf -oL docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/dataapi:latest
    stdbuf -oL docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/frontend:latest
    stdbuf -oL docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/media:latest
    
    echo -e "${GREEN}Images pushed to ECR${NC}"
}

setup_vpc_endpoints() {
    echo -e "${GREEN}Setting up VPC Endpoints...${NC}"
    
    # AWS CLI COMMANDS: Create VPC endpoints for ECR API and Docker registry access
    aws ec2 create-vpc-endpoint \
        --vpc-id REPLACE_VPC_ID \
        --vpc-endpoint-type Interface \
        --service-name com.amazonaws.REPLACE_AWS_REGION.ecr.api \
        --subnet-ids REPLACE_PRIVATE_SUBNET_1 REPLACE_PRIVATE_SUBNET_2 \
        --security-group-ids REPLACE_SECURITY_GROUP_APP \
        --no-cli-pager

    aws ec2 create-vpc-endpoint \
        --vpc-id REPLACE_VPC_ID \
        --vpc-endpoint-type Interface \
        --service-name com.amazonaws.REPLACE_AWS_REGION.ecr.dkr \
        --subnet-ids REPLACE_PRIVATE_SUBNET_1 REPLACE_PRIVATE_SUBNET_2 \
        --security-group-ids REPLACE_SECURITY_GROUP_APP \
        --no-cli-pager
        
    echo -e "${GREEN}VPC Endpoints created${NC}"
}

deploy_ecs_cluster() {
    echo -e "${GREEN}Deploying ECS Cluster...${NC}"
    
    # AWS CLI COMMANDS: Create ECS cluster with EC2 capacity provider and auto scaling
    USERDATA=$(base64 -w 0 /home/ec2-user/workspace/my-workspace/workshop/ec2_user_data.sh)
    ECS_AMI_ID=$(aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended/image_id --query "Parameters[0].Value" --output text)

    echo "Creating launch template..."
    aws ec2 create-launch-template \
        --launch-template-name REPLACE_PREFIX_CODE-launchtemplate-ecs \
        --version-description 1 \
        --launch-template-data "{
            \"ImageId\": \"$ECS_AMI_ID\",
            \"InstanceType\": \"t4g.small\",
            \"UserData\": \"$USERDATA\",
            \"IamInstanceProfile\": {
                \"Name\": \"REPLACE_PREFIX_CODE-iamprofile-ecs\"
            },
            \"SecurityGroupIds\": [\"REPLACE_SECURITY_GROUP_APP\"],
            \"KeyName\": \"REPLACE_PREFIX_CODE-ec2-keypair\"
        }"

    echo "Creating auto scaling group..."
    aws autoscaling create-auto-scaling-group \
        --auto-scaling-group-name REPLACE_PREFIX_CODE-asg-ecs \
        --launch-template LaunchTemplateName=REPLACE_PREFIX_CODE-launchtemplate-ecs \
        --min-size 2 \
        --max-size 2 \
        --desired-capacity 2 \
        --vpc-zone-identifier "REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2" \
        --tags ResourceId=REPLACE_PREFIX_CODE-asg-ecs,ResourceType=auto-scaling-group,Key=Name,Value=REPLACE_PREFIX_CODE-ecs-instance,PropagateAtLaunch=true

    ASG_ARN=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names REPLACE_PREFIX_CODE-asg-ecs --query 'AutoScalingGroups[0].AutoScalingGroupARN' --output text)
    save_variable "ASG_ARN" "$ASG_ARN"

    echo "Enabling container insights..."
    aws ecs put-account-setting --name containerInsights --value enhanced

    echo "Creating ECS cluster..."
    aws ecs create-cluster \
        --cluster-name REPLACE_PREFIX_CODE-ecs \
        --service-connect-defaults namespace=REPLACE_PREFIX_CODE \
        --settings name=containerInsights,value=enhanced \
        --no-cli-pager

    echo "Waiting for cluster to be active..."
    until aws ecs describe-clusters --clusters REPLACE_PREFIX_CODE-ecs --query 'clusters[0].status' --output text | grep -q ACTIVE; do sleep 5; done
    sleep 5

    echo "Creating capacity provider..."
    aws ecs create-capacity-provider \
        --name REPLACE_PREFIX_CODE-capacity-ec2 \
        --auto-scaling-group-provider "{
            \"autoScalingGroupArn\": \"$ASG_ARN\",
            \"managedScaling\": {
                \"status\": \"ENABLED\",
                \"targetCapacity\": 100,
                \"minimumScalingStepSize\": 1,
                \"maximumScalingStepSize\": 10000,
                \"instanceWarmupPeriod\": 300
            },
            \"managedTerminationProtection\": \"DISABLED\",
            \"managedDraining\": \"ENABLED\"
        }" \
        --no-cli-pager

    echo "Configuring cluster capacity providers..."
    aws ecs put-cluster-capacity-providers \
        --cluster REPLACE_PREFIX_CODE-ecs \
        --capacity-providers FARGATE FARGATE_SPOT REPLACE_PREFIX_CODE-capacity-ec2 \
        --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
        --no-cli-pager
    echo "Waiting for EC2 instances to register..."
    until [ "$(aws ecs describe-clusters --clusters wildlife-ecs --query 'clusters[0].registeredContainerInstancesCount' --output text)" -gt 0 ]; do sleep 10; done

    echo -e "${GREEN}✅ ECS Cluster deployed${NC}"
}

register_task_definitions() {
    echo -e "${GREEN}Registering Task Definitions...${NC}"
    
    # AWS CLI COMMANDS: Register ECS task definitions for each microservice
    aws ecs register-task-definition \
        --cli-input-json file://$HOME/workspace/my-workspace/container-app/alerts/task_definition_alerts_v1.json \
        --no-cli-pager

    aws ecs register-task-definition \
        --cli-input-json file://$HOME/workspace/my-workspace/container-app/datadb/task_definition_datadb_v1.json \
        --no-cli-pager

    aws ecs register-task-definition \
        --cli-input-json file://$HOME/workspace/my-workspace/container-app/dataapi/task_definition_dataapi_v1.json \
        --no-cli-pager

    aws ecs register-task-definition \
        --cli-input-json file://$HOME/workspace/my-workspace/container-app/frontend/task_definition_frontend_v1.json \
        --no-cli-pager

    aws ecs register-task-definition \
        --cli-input-json file://$HOME/workspace/my-workspace/container-app/media/task_definition_media_v1.json \
        --no-cli-pager
        
    echo -e "${GREEN}✅ Task definitions registered${NC}"
}

create_load_balancer() {
    echo -e "${GREEN}Creating Load Balancer...${NC}"
    
    # AWS CLI COMMANDS: Create Application Load Balancer with target group and listener
    echo "Creating target group..."
    TG_ARN=$(aws elbv2 create-target-group \
        --name REPLACE_PREFIX_CODE-targetgroup-ecs \
        --protocol HTTP \
        --port 5000 \
        --vpc-id REPLACE_VPC_ID \
        --target-type ip \
        --health-check-path /REPLACE_PREFIX_CODE/health \
        --health-check-interval-seconds 30 \
        --health-check-timeout-seconds 5 \
        --healthy-threshold-count 2 \
        --unhealthy-threshold-count 2 \
        --ip-address-type ipv4 \
        --output text \
        --query 'TargetGroups[0].TargetGroupArn')

    echo "Creating application load balancer..."
    ALB_ARN=$(aws elbv2 create-load-balancer \
        --name REPLACE_PREFIX_CODE-alb-ecs \
        --subnets REPLACE_PUBLIC_SUBNET_1 REPLACE_PUBLIC_SUBNET_2 \
        --security-groups REPLACE_SECURITY_GROUP_ALB \
        --scheme internet-facing \
        --type application \
        --output text \
        --query 'LoadBalancers[0].LoadBalancerArn')

    echo "Creating listener..."
    aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TG_ARN --no-cli-pager
    
    # Save load balancer variables persistently
    save_variable "ALB_ARN" "$ALB_ARN"
    save_variable "TG_ARN" "$TG_ARN"
    
    echo -e "${GREEN}✅ Load balancer created${NC}"
}

create_ecs_services() {
    echo -e "${GREEN}Creating ECS Services...${NC}"
    
    # AWS CLI COMMANDS: Create ECS services for each microservice with service connect
    TG_ARN=$(aws elbv2 describe-target-groups --names REPLACE_PREFIX_CODE-targetgroup-ecs --query 'TargetGroups[0].TargetGroupArn' --output text)
    
    echo "Creating datadb service..."
    aws ecs create-service \
        --cluster REPLACE_PREFIX_CODE-ecs \
        --service-name REPLACE_PREFIX_CODE-datadb-service \
        --task-definition REPLACE_PREFIX_CODE-datadb-task \
        --desired-count 1 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2],securityGroups=[REPLACE_SECURITY_GROUP_APP],assignPublicIp=DISABLED}" \
        --service-connect-configuration "enabled=true,namespace=REPLACE_PREFIX_CODE,services=[{portName=data-tcp,discoveryName=REPLACE_PREFIX_CODE-datadb,clientAliases=[{port=27017}]}],logConfiguration={logDriver=awslogs,options={awslogs-group=/aws/ecs/service-connect/REPLACE_PREFIX_CODE-app,awslogs-region=REPLACE_AWS_REGION,awslogs-stream-prefix=REPLACE_PREFIX_CODE}}" \
        --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" \
        --no-cli-pager

    echo "Waiting for datadb service to stabilize..."
    aws ecs wait services-stable --cluster REPLACE_PREFIX_CODE-ecs --services REPLACE_PREFIX_CODE-datadb-service --region REPLACE_AWS_REGION

    echo "Creating dataapi service..."
    aws ecs create-service \
        --cluster REPLACE_PREFIX_CODE-ecs \
        --service-name REPLACE_PREFIX_CODE-dataapi-service \
        --task-definition REPLACE_PREFIX_CODE-dataapi-task \
        --desired-count 2 \
        --capacity-provider-strategy capacityProvider=REPLACE_PREFIX_CODE-capacity-ec2,weight=1 \
        --network-configuration "awsvpcConfiguration={subnets=[REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2],securityGroups=[REPLACE_SECURITY_GROUP_APP],assignPublicIp=DISABLED}" \
        --service-connect-configuration "enabled=true,namespace=REPLACE_PREFIX_CODE,services=[{portName=data-http,discoveryName=REPLACE_PREFIX_CODE-dataapi,clientAliases=[{port=5000}]}],logConfiguration={logDriver=awslogs,options={awslogs-group=/aws/ecs/service-connect/REPLACE_PREFIX_CODE-app,awslogs-region=REPLACE_AWS_REGION,awslogs-stream-prefix=REPLACE_PREFIX_CODE}}" \
        --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" \
        --no-cli-pager

    echo "Creating alerts service..."
    aws ecs create-service \
        --cluster REPLACE_PREFIX_CODE-ecs \
        --service-name REPLACE_PREFIX_CODE-alerts-service \
        --task-definition REPLACE_PREFIX_CODE-alerts-task \
        --desired-count 2 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2],securityGroups=[REPLACE_SECURITY_GROUP_APP],assignPublicIp=DISABLED}" \
        --service-connect-configuration "enabled=true,namespace=REPLACE_PREFIX_CODE,services=[{portName=alerts-http,discoveryName=REPLACE_PREFIX_CODE-alerts,clientAliases=[{port=5000}]}],logConfiguration={logDriver=awslogs,options={awslogs-group=/aws/ecs/service-connect/REPLACE_PREFIX_CODE-app,awslogs-region=REPLACE_AWS_REGION,awslogs-stream-prefix=REPLACE_PREFIX_CODE}}" \
        --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" \
        --no-cli-pager

    echo "Creating media service..."
    aws ecs create-service \
        --cluster REPLACE_PREFIX_CODE-ecs \
        --service-name REPLACE_PREFIX_CODE-media-service \
        --task-definition REPLACE_PREFIX_CODE-media-task \
        --desired-count 2 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2],securityGroups=[REPLACE_SECURITY_GROUP_APP],assignPublicIp=DISABLED}" \
        --service-connect-configuration "enabled=true,namespace=REPLACE_PREFIX_CODE,services=[{portName=media-http,discoveryName=REPLACE_PREFIX_CODE-media,clientAliases=[{port=5000}]}],logConfiguration={logDriver=awslogs,options={awslogs-group=/aws/ecs/service-connect/REPLACE_PREFIX_CODE-app,awslogs-region=REPLACE_AWS_REGION,awslogs-stream-prefix=REPLACE_PREFIX_CODE}}" \
        --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" \
        --no-cli-pager

    echo "Creating frontend service..."
    aws ecs create-service \
        --cluster REPLACE_PREFIX_CODE-ecs \
        --service-name REPLACE_PREFIX_CODE-frontend-service \
        --task-definition REPLACE_PREFIX_CODE-frontend-task \
        --desired-count 2 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2],securityGroups=[REPLACE_SECURITY_GROUP_APP],assignPublicIp=DISABLED}" \
        --service-connect-configuration "enabled=true,namespace=REPLACE_PREFIX_CODE,services=[{portName=frontend-http,discoveryName=REPLACE_PREFIX_CODE-frontend,clientAliases=[{port=5000}]}],logConfiguration={logDriver=awslogs,options={awslogs-group=/aws/ecs/service-connect/REPLACE_PREFIX_CODE-app,awslogs-region=REPLACE_AWS_REGION,awslogs-stream-prefix=REPLACE_PREFIX_CODE}}" \
        --load-balancers "targetGroupArn=$TG_ARN,containerName=REPLACE_PREFIX_CODE-frontend,containerPort=5000" \
        --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" \
        --no-cli-pager

    echo ""
    echo -e "${CYAN}Waiting for all services to start running...${NC}"
    
    # Array of services to check
    services=("REPLACE_PREFIX_CODE-datadb-service" "REPLACE_PREFIX_CODE-dataapi-service" "REPLACE_PREFIX_CODE-alerts-service" "REPLACE_PREFIX_CODE-media-service" "REPLACE_PREFIX_CODE-frontend-service")
    total_services=${#services[@]}
    
    # Check each service status
    while true; do
        running_count=0
        
        for i in "${!services[@]}"; do
            service=${services[$i]}
            service_num=$((i + 1))
            
            # Get running task count for this service
            running_tasks=$(aws ecs describe-services --cluster REPLACE_PREFIX_CODE-ecs --services $service --query 'services[0].runningCount' --output text 2>/dev/null)
            desired_tasks=$(aws ecs describe-services --cluster REPLACE_PREFIX_CODE-ecs --services $service --query 'services[0].desiredCount' --output text 2>/dev/null)
            
            if [ "$running_tasks" = "$desired_tasks" ] && [ "$running_tasks" != "0" ]; then
                echo -e "${GREEN}✅ Service $service_num/$total_services: $service is running ($running_tasks/$desired_tasks tasks)${NC}"
                ((running_count++))
            else
                echo -e "${YELLOW}⏳ Service $service_num/$total_services: $service is starting ($running_tasks/$desired_tasks tasks)${NC}"
            fi
        done
        
        # If all services are running, break the loop
        if [ $running_count -eq $total_services ]; then
            break
        fi
        
        echo "Checking again in 30 seconds..."
        sleep 30
        echo ""
    done

    echo ""
    echo -e "${GREEN}🎉 Congratulations! Your Wildlife application is up! Connect at: http://$(aws elbv2 describe-load-balancers --names REPLACE_PREFIX_CODE-alb-ecs --query 'LoadBalancers[0].DNSName' --output text)/REPLACE_PREFIX_CODE${NC}"
}

fix_image_upload() {
    echo -e "${GREEN}Fixing Image Upload...${NC}"
    
    # AWS CLI COMMANDS: Attach S3 policy to ECS task role and force service deployment
    aws iam attach-role-policy \
        --role-name REPLACE_PREFIX_CODE-iamrole-ecs-task \
        --policy-arn arn:aws:iam::REPLACE_AWS_ACCOUNT_ID:policy/REPLACE_PREFIX_CODE-iampolicy-s3

    echo "Forcing new deployment for media service..."
    aws ecs update-service \
        --cluster REPLACE_PREFIX_CODE-ecs \
        --service REPLACE_PREFIX_CODE-media-service \
        --force-new-deployment \
        --no-cli-pager
        
    echo -e "${GREEN}✅ Image Upload Fixed${NC}"
}

fix_gps_data() {
    echo -e "${GREEN}Fixing GPS data...${NC}"
    
    # AWS CLI COMMANDS: Update Lambda function environment variable with ALB DNS
    ALB_DNS=$(aws elbv2 describe-load-balancers --names REPLACE_PREFIX_CODE-alb-ecs --query 'LoadBalancers[0].DNSName' --output text)
    save_variable "ALB_DNS" "$ALB_DNS"
    aws lambda update-function-configuration --function-name REPLACE_PREFIX_CODE-lambda-gps --environment "Variables={API_ENDPOINT=http://$ALB_DNS/REPLACE_PREFIX_CODE/api/gps}" --no-cli-pager
    
    echo -e "${GREEN}✅ GPS Data Fixed${NC}"
}

create_efs_storage() {
    echo -e "${GREEN}Creating EFS Storage...${NC}"
    
    # AWS CLI COMMANDS: Create EFS file system with mount targets for persistent storage
    aws iam attach-role-policy \
        --role-name REPLACE_PREFIX_CODE-iamrole-ecs-task \
        --policy-arn arn:aws:iam::REPLACE_AWS_ACCOUNT_ID:policy/REPLACE_PREFIX_CODE-iampolicy-efs \
        --no-cli-pager
    
    EFS_ID=$(aws efs create-file-system \
        --creation-token REPLACE_PREFIX_CODE-mongodb-$(date +%s) \
        --performance-mode generalPurpose \
        --throughput-mode provisioned \
        --provisioned-throughput-in-mibps 100 \
        --encrypted \
        --tags Key=Name,Value=REPLACE_PREFIX_CODE-mongodb-efs \
        --query 'FileSystemId' \
        --output text)
    
    echo "Waiting for EFS to be available..."
    until [ "$(aws efs describe-file-systems --file-system-id $EFS_ID --query 'FileSystems[0].LifeCycleState' --output text)" = "available" ]; do 
        echo "EFS still creating, waiting..."
        sleep 10
    done

    echo "Creating mount targets..."   
    aws efs create-mount-target \
        --file-system-id $EFS_ID \
        --subnet-id REPLACE_PRIVATE_SUBNET_1 \
        --security-groups REPLACE_SECURITY_GROUP_APP \
        --no-cli-pager
    
    aws efs create-mount-target \
        --file-system-id $EFS_ID \
        --subnet-id REPLACE_PRIVATE_SUBNET_2 \
        --security-groups REPLACE_SECURITY_GROUP_APP \
        --no-cli-pager

    echo "Waiting for mount targets to be available..."
    until [ "$(aws efs describe-mount-targets --file-system-id $EFS_ID --query 'length(MountTargets[?LifeCycleState==`available`])' --output text)" = "2" ]; do 
        echo "Mount targets still creating, waiting..."
        sleep 10
    done

    echo "Updating task definition with EFS ID: $EFS_ID"
    save_variable "EFS_ID" "$EFS_ID"
    sleep 10
    sed -i "s/REPLACE_EFS_ID/$EFS_ID/g" /home/ec2-user/workspace/my-workspace/container-app/datadb/task_definition_datadb_v2.json

    aws ecs register-task-definition \
        --cli-input-json file:///home/ec2-user/workspace/my-workspace/container-app/datadb/task_definition_datadb_v2.json \
        --no-cli-pager
    
    aws ecs update-service \
        --cluster REPLACE_PREFIX_CODE-ecs \
        --service REPLACE_PREFIX_CODE-datadb-service \
        --task-definition REPLACE_PREFIX_CODE-datadb-task \
        --force-new-deployment \
        --no-cli-pager
    
    echo "Waiting for service to stabilize..."
    aws ecs wait services-stable \
        --cluster REPLACE_PREFIX_CODE-ecs \
        --services REPLACE_PREFIX_CODE-datadb-service \
        --region REPLACE_AWS_REGION
    
    echo -e "${GREEN}✅ EFS Storage created and configured${NC}"
    echo -e "${CYAN}EFS ID: $EFS_ID${NC}"
}

configure_service_scaling() {
    echo -e "${GREEN}Configuring Frontend Service Auto Scaling...${NC}"
    
    # AWS CLI COMMANDS: Configure ECS service auto scaling for frontend service
    echo "Registering scalable target for frontend service..."
    aws application-autoscaling register-scalable-target \
        --service-namespace ecs \
        --resource-id service/REPLACE_PREFIX_CODE-ecs/REPLACE_PREFIX_CODE-frontend-service \
        --scalable-dimension ecs:service:DesiredCount \
        --min-capacity 2 \
        --max-capacity 5 \
        --no-cli-pager
    
    echo "Creating CPU-based scaling policy..."
    aws application-autoscaling put-scaling-policy \
        --service-namespace ecs \
        --resource-id service/REPLACE_PREFIX_CODE-ecs/REPLACE_PREFIX_CODE-frontend-service \
        --scalable-dimension ecs:service:DesiredCount \
        --policy-name REPLACE_PREFIX_CODE-frontend-cpu-scaling \
        --policy-type TargetTrackingScaling \
        --target-tracking-scaling-policy-configuration '{
            "TargetValue": 70.0,
            "PredefinedMetricSpecification": {
                "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
            },
            "ScaleOutCooldown": 300,
            "ScaleInCooldown": 300
        }' \
        --no-cli-pager
    
    echo ""
    echo -e "${GREEN}✅ Service Auto Scaling configured${NC}"
}

configure_capacity_scaling() {
    echo -e "${GREEN}Configuring Capacity Auto Scaling...${NC}"
    
    # AWS CLI COMMANDS: Update Auto Scaling Group to allow scaling up to 4 instances for capacity scaling
    echo "Updating Auto Scaling Group max capacity for capacity scaling..."
    aws autoscaling update-auto-scaling-group \
        --auto-scaling-group-name REPLACE_PREFIX_CODE-asg-ecs \
        --max-size 4 \
        --no-cli-pager
    
    # AWS CLI COMMANDS: Configure ECS service auto scaling for DataAPI to trigger capacity scaling
    echo "Configuring DataAPI service auto scaling..."
    aws application-autoscaling register-scalable-target \
        --service-namespace ecs \
        --resource-id service/REPLACE_PREFIX_CODE-ecs/REPLACE_PREFIX_CODE-dataapi-service \
        --scalable-dimension ecs:service:DesiredCount \
        --min-capacity 2 \
        --max-capacity 6 \
        --no-cli-pager
    
    aws application-autoscaling put-scaling-policy \
        --service-namespace ecs \
        --resource-id service/REPLACE_PREFIX_CODE-ecs/REPLACE_PREFIX_CODE-dataapi-service \
        --scalable-dimension ecs:service:DesiredCount \
        --policy-name REPLACE_PREFIX_CODE-dataapi-cpu-scaling \
        --policy-type TargetTrackingScaling \
        --target-tracking-scaling-policy-configuration '{
            "TargetValue": 70.0,
            "PredefinedMetricSpecification": {
                "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
            }
        }' \
        --no-cli-pager
    
    echo -e "${GREEN}✅ Capacity Auto Scaling configured${NC}"
}

check_status() {
    echo -e "${GREEN}Checking Deployment Status...${NC}"
    
    # AWS CLI COMMANDS: Query ECS cluster and service status information
    echo ""
    echo -e "${CYAN}ECS Cluster Status:${NC}"
    aws ecs describe-clusters --clusters REPLACE_PREFIX_CODE-ecs --query 'clusters[0].{Status:status,ActiveServices:activeServicesCount,RunningTasks:runningTasksCount}' --output table 2>/dev/null || echo "Cluster not found"
    
    echo ""
    echo -e "${CYAN}ECS Services:${NC}"
    aws ecs list-services --cluster REPLACE_PREFIX_CODE-ecs --query 'serviceArns[]' --output table 2>/dev/null || echo "No services found"
    
    echo ""
    echo -e "${CYAN}Service Status Details:${NC}"
    for service in REPLACE_PREFIX_CODE-datadb-service REPLACE_PREFIX_CODE-dataapi-service REPLACE_PREFIX_CODE-alerts-service REPLACE_PREFIX_CODE-media-service REPLACE_PREFIX_CODE-frontend-service; do
        status=$(aws ecs describe-services --cluster REPLACE_PREFIX_CODE-ecs --services $service --query 'services[0].{Service:serviceName,Status:status,Running:runningCount,Desired:desiredCount}' --output table 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "$status"
        fi
    done
}

show_app_url() {
    echo -e "${GREEN}Getting Application URL...${NC}"
    
    # AWS CLI COMMANDS: Get Application Load Balancer DNS name for application access
    ALB_DNS=$(aws elbv2 describe-load-balancers --names REPLACE_PREFIX_CODE-alb-ecs --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null)
    if [ "$ALB_DNS" != "None" ] && [ "$ALB_DNS" != "" ]; then
        echo ""
        echo -e "${CYAN}🌐 Application URL:${NC}"
        echo "   http://$ALB_DNS/REPLACE_PREFIX_CODE"
        echo ""
        echo -e "${CYAN}📊 Health Check:${NC}"
        echo "   http://$ALB_DNS/REPLACE_PREFIX_CODE/health"
    else
        echo -e "${YELLOW}Load balancer not found or not ready yet${NC}"
    fi
}

run_service_scaling_test() {
    echo -e "${GREEN}Running Service Scaling Test...${NC}"
    
    # Get ALB DNS for load testing
    ALB_DNS=$(aws elbv2 describe-load-balancers --names REPLACE_PREFIX_CODE-alb-ecs --query 'LoadBalancers[0].DNSName' --output text --region REPLACE_AWS_REGION 2>/dev/null)
    
    if [ "$ALB_DNS" = "None" ] || [ "$ALB_DNS" = "" ]; then
        echo -e "${RED}❌ Wildlife ALB not found. Deploy containerized app first.${NC}"
        return 1
    fi
    
    # Show the command being executed
    echo -e "${CYAN}Command: ALB_URL=http://$ALB_DNS k6 run loadtest-service-scaling.js${NC}"
    
    # Run k6 test with ALB URL
    ALB_URL="http://$ALB_DNS" k6 run loadtest-service-scaling.js
}

run_capacity_scaling_test() {
    echo -e "${GREEN}Running Capacity Scaling Test...${NC}"
    
    # AWS CLI COMMANDS: Get Application Load Balancer DNS name for capacity scaling load test
    ALB_DNS=$(aws elbv2 describe-load-balancers --names REPLACE_PREFIX_CODE-alb-ecs --query 'LoadBalancers[0].DNSName' --output text --region REPLACE_AWS_REGION 2>/dev/null)
    
    if [ "$ALB_DNS" = "None" ] || [ "$ALB_DNS" = "" ]; then
        echo -e "${RED}❌ Wildlife ALB not found. Deploy containerized app first.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}This test will trigger DataAPI service scaling which should trigger EC2 capacity scaling${NC}"
    echo -e "${CYAN}Monitor ECS console and EC2 Auto Scaling Groups to see infrastructure scaling${NC}"
    echo ""
    
    # Show the command being executed
    echo -e "${CYAN}Command: ALB_URL=http://$ALB_DNS k6 run loadtest-capacity-scaling.js${NC}"
    
    # Run k6 test with ALB URL - this should trigger DataAPI scaling and then capacity scaling
    ALB_URL="http://$ALB_DNS" k6 run loadtest-capacity-scaling.js
}

full_build() {
    echo -e "${GREEN}Running Full Build...${NC}"
    echo "This will run all build commands in sequence"
    
    if [ "$CI_MODE" = "true" ]; then
        confirm="y"
        echo "🤖 CI Mode: Auto-confirming setup"
    else
        echo -n "Continue? (y/n): "
        read confirm
    fi
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        create_ecr_repos && \
        build_images && \
        push_images && \
        setup_vpc_endpoints && \
        deploy_ecs_cluster && \
        register_task_definitions && \
        create_load_balancer && \
        create_ecs_services && \
        fix_image_upload && \
        fix_gps_data && \
        create_efs_storage && \
        configure_service_scaling
        echo -e "${GREEN}✅ Full setup completed!${NC}"
    else
        echo "Setup cancelled"
    fi
}

# =============================================================================
# CLEANUP COMMANDS
# =============================================================================

cleanup_services() {
    echo -e "${RED}Deleting ECS Services...${NC}"
    
    # AWS CLI COMMANDS: Scale down and delete all ECS services
    echo "Scaling down services to 0..."
    aws ecs update-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-frontend-service --desired-count 0 --no-cli-pager
    aws ecs update-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-media-service --desired-count 0 --no-cli-pager
    aws ecs update-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-alerts-service --desired-count 0 --no-cli-pager
    aws ecs update-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-dataapi-service --desired-count 0 --no-cli-pager
    aws ecs update-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-datadb-service --desired-count 0 --no-cli-pager

    echo "Waiting for services to scale down..."
    aws ecs wait services-stable --cluster REPLACE_PREFIX_CODE-ecs --services REPLACE_PREFIX_CODE-frontend-service REPLACE_PREFIX_CODE-media-service REPLACE_PREFIX_CODE-alerts-service REPLACE_PREFIX_CODE-dataapi-service REPLACE_PREFIX_CODE-datadb-service

    echo "Deleting services..."
    aws ecs delete-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-frontend-service --force --no-cli-pager
    aws ecs delete-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-media-service --force --no-cli-pager
    aws ecs delete-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-alerts-service --force --no-cli-pager
    aws ecs delete-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-dataapi-service --force --no-cli-pager
    aws ecs delete-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-datadb-service --force --no-cli-pager
    echo -e "${GREEN}✅ ECS Services deleted${NC}"
}

cleanup_load_balancer() {
    echo -e "${RED}Deleting Load Balancer...${NC}"
    
    # AWS CLI COMMANDS: Delete Application Load Balancer, listeners, and target groups
    ALB_ARN=$(aws elbv2 describe-load-balancers --names REPLACE_PREFIX_CODE-alb-ecs --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
    if [ "$ALB_ARN" != "None" ] && [ "$ALB_ARN" != "" ]; then
        echo "Deleting listeners..."
        LISTENER_ARNS=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query 'Listeners[].ListenerArn' --output text 2>/dev/null)
        for LISTENER_ARN in $LISTENER_ARNS; do
            aws elbv2 delete-listener --listener-arn $LISTENER_ARN --no-cli-pager
        done
        
        echo "Deleting load balancer..."
        aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN --no-cli-pager
    fi

    echo "Deleting target group..."
    TG_ARN=$(aws elbv2 describe-target-groups --names REPLACE_PREFIX_CODE-targetgroup-ecs --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)
    if [ "$TG_ARN" != "None" ] && [ "$TG_ARN" != "" ]; then
        aws elbv2 delete-target-group --target-group-arn $TG_ARN --no-cli-pager
    fi
    
    # Clear load balancer variables
    save_variable "ALB_ARN" ""
    save_variable "ALB_DNS" ""
    save_variable "TG_ARN" ""
    
    echo -e "${GREEN}✅ Load Balancer deleted${NC}"
}

cleanup_cluster() {
    echo -e "${RED}Deleting ECS Cluster...${NC}"
    
    # AWS CLI COMMANDS: Delete ECS cluster, capacity providers, and container instances
    if ! aws ecs describe-clusters --clusters REPLACE_PREFIX_CODE-ecs --query 'clusters[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
        echo "Cluster not found, skipping deletion"
        echo -e "${GREEN}✅ ECS Cluster deleted (was already gone)${NC}"
        return 0
    fi
    
    echo "Removing capacity providers and deleting cluster..."
    aws ecs put-cluster-capacity-providers --cluster REPLACE_PREFIX_CODE-ecs --capacity-providers --default-capacity-provider-strategy --no-cli-pager 2>/dev/null
    aws ecs delete-capacity-provider --capacity-provider REPLACE_PREFIX_CODE-capacity-ec2 --no-cli-pager 2>/dev/null
    aws ecs delete-cluster --cluster REPLACE_PREFIX_CODE-ecs --no-cli-pager 2>/dev/null
    
    echo -e "${GREEN}✅ ECS Cluster deleted${NC}"
}

cleanup_asg() {
    echo -e "${RED}Deleting Auto Scaling Group...${NC}"
    
    # AWS CLI COMMANDS: Delete Auto Scaling Group and launch template
    echo "Force deleting ASG..."
    aws autoscaling delete-auto-scaling-group --auto-scaling-group-name REPLACE_PREFIX_CODE-asg-ecs --force-delete --no-cli-pager
    
    echo "Waiting for Auto Scaling Group to be deleted..."
    while aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names REPLACE_PREFIX_CODE-asg-ecs --query 'AutoScalingGroups[0].AutoScalingGroupName' --output text 2>/dev/null | grep -q REPLACE_PREFIX_CODE-asg-ecs; do
        sleep 5
    done
    
    echo "Deleting launch template..."
    aws ec2 delete-launch-template --launch-template-name REPLACE_PREFIX_CODE-launchtemplate-ecs --no-cli-pager
    
    # Clear ASG variable
    save_variable "ASG_ARN" ""
    
    echo -e "${GREEN}✅ Auto Scaling Group deleted${NC}"
}

cleanup_task_definitions() {
    echo -e "${RED}Deregistering Task Definitions...${NC}"
    
    # AWS CLI COMMANDS: Deregister all task definition revisions for each service
    for TASK_DEF in REPLACE_PREFIX_CODE-alerts-task REPLACE_PREFIX_CODE-datadb-task REPLACE_PREFIX_CODE-dataapi-task REPLACE_PREFIX_CODE-frontend-task REPLACE_PREFIX_CODE-media-task; do
        echo "Deregistering $TASK_DEF..."
        REVISIONS=$(aws ecs list-task-definitions --family-prefix $TASK_DEF --query 'taskDefinitionArns[]' --output text 2>/dev/null)
        for REVISION in $REVISIONS; do
            aws ecs deregister-task-definition --task-definition $REVISION --no-cli-pager
        done
    done
    echo -e "${GREEN}✅ Task Definitions deregistered${NC}"
}

cleanup_vpc_endpoints() {
    echo -e "${RED}Deleting VPC Endpoints...${NC}"
    
    # AWS CLI COMMANDS: Delete VPC endpoints for ECR access
    VPC_ENDPOINTS=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=REPLACE_VPC_ID" "Name=service-name,Values=com.amazonaws.REPLACE_AWS_REGION.ecr.*" --query 'VpcEndpoints[].VpcEndpointId' --output text 2>/dev/null)
    for ENDPOINT_ID in $VPC_ENDPOINTS; do
        echo "Deleting VPC endpoint $ENDPOINT_ID..."
        aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $ENDPOINT_ID --no-cli-pager
    done
    echo -e "${GREEN}✅ VPC Endpoints deleted${NC}"
}

cleanup_efs() {
    echo -e "${RED}Deleting EFS Storage...${NC}"
    
    # AWS CLI COMMANDS: Delete EFS file systems and mount targets
    EFS_FILESYSTEMS=$(aws efs describe-file-systems --query 'FileSystems[?Tags[?Key==`Name` && contains(Value, `REPLACE_PREFIX_CODE-mongodb-efs`)]].FileSystemId' --output text 2>/dev/null)
        
        echo "Deleting mount targets for $EFS_ID..."
        MOUNT_TARGETS=$(aws efs describe-mount-targets --file-system-id $EFS_ID --query 'MountTargets[].MountTargetId' --output text 2>/dev/null)
        for MT_ID in $MOUNT_TARGETS; do
            aws efs delete-mount-target --mount-target-id $MT_ID --no-cli-pager 2>/dev/null
        done
        
        echo "Waiting for mount targets to be deleted..."
        until [ "$(aws efs describe-mount-targets --file-system-id $EFS_ID --query 'length(MountTargets)' --output text 2>/dev/null)" = "0" ]; do sleep 5; done
        
        echo "Deleting file system $EFS_ID..."
        aws efs delete-file-system --file-system-id $EFS_ID --no-cli-pager 2>/dev/null
    done
    
    # Reset task definition back to placeholders
    echo "Resetting task definition placeholders..."
    sed -i 's/"fileSystemId": "fs-[^"]*"/"fileSystemId": "REPLACE_EFS_ID"/g' /home/ec2-user/workspace/my-workspace/container-app/datadb/task_definition_datadb_v2.json

    # Clear EFS_ID variable
    save_variable "EFS_ID" ""
    
    echo -e "${GREEN}✅ EFS Storage deleted${NC}"
}

cleanup_ecr() {
    echo -e "${RED}Deleting ECR Repositories...${NC}"
    
    # AWS CLI COMMANDS: Delete ECR repositories and all container images
    for REPO in REPLACE_PREFIX_CODE/alerts REPLACE_PREFIX_CODE/datadb REPLACE_PREFIX_CODE/dataapi REPLACE_PREFIX_CODE/frontend REPLACE_PREFIX_CODE/media; do
        echo "Deleting repository $REPO..."
        aws ecr delete-repository --repository-name $REPO --force --no-cli-pager 2>/dev/null
    done
    echo -e "${GREEN}✅ ECR Repositories deleted${NC}"
}

cleanup_docker() {
    echo -e "${RED}Cleaning up Docker Images...${NC}"
    
    # DOCKER COMMANDS: Remove local container images and clean up Docker resources
    echo "Removing local REPLACE_PREFIX_CODE images..."
    docker rmi REPLACE_PREFIX_CODE/alerts REPLACE_PREFIX_CODE/datadb REPLACE_PREFIX_CODE/dataapi REPLACE_PREFIX_CODE/frontend REPLACE_PREFIX_CODE/media 2>/dev/null
    docker rmi REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/alerts:latest 2>/dev/null
    docker rmi REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/datadb:latest 2>/dev/null
    docker rmi REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/dataapi:latest 2>/dev/null
    docker rmi REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/frontend:latest 2>/dev/null
    docker rmi REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/REPLACE_PREFIX_CODE/media:latest 2>/dev/null

    echo "Cleaning up unused Docker resources..."
    docker system prune -f
    echo -e "${GREEN}✅ Docker images cleaned${NC}"
}

full_cleanup() {
    echo -e "${RED}⚠️  This will delete ALL REPLACE_PREFIX_CODE infrastructure!${NC}"
    
    if [ "$CI_MODE" = "true" ]; then
        confirm="DELETE"
        echo "🤖 CI Mode: Auto-confirming cleanup"
    else
        echo -n "Type 'DELETE' to confirm: "
        read confirm
    fi
    
    if [ "$confirm" = "DELETE" ]; then
        echo -e "${RED}🔥 Starting complete infrastructure cleanup...${NC}"
        cleanup_services && \
        cleanup_load_balancer && \
        cleanup_cluster && \
        cleanup_asg && \
        cleanup_task_definitions && \
        cleanup_vpc_endpoints && \
        cleanup_efs && \
        cleanup_ecr && \
        cleanup_docker
        
        echo ""
        echo -e "${GREEN}🎯 Complete cleanup finished!${NC}"
        echo -e "${YELLOW}Note: CloudFormation deployed resources remain${NC}"
    else
        echo "Cleanup cancelled"
    fi
}

exit_menu() {
    echo -e "${GREEN}Goodbye! 🦁${NC}"
    exit 0
}

# =============================================================================
# MAIN MENU LOOP
# =============================================================================

# Load persistent variables at startup
load_variables

# Handle command line execution for CI/automation
if [ "$CI_MODE" = "true" ] && [ -n "$CI_COMMAND" ]; then
    echo "🤖 CI Mode: Executing command '$CI_COMMAND'"
    case $CI_COMMAND in
        full_setup)
            full_setup
            exit $?
            ;;
        full_cleanup)
            full_cleanup
            exit $?
            ;;
        test_deployment)
            echo "🤖 CI Mode: Running full deployment test"
            full_setup
            setup_result=$?
            if [ $setup_result -eq 0 ]; then
                echo "✅ Deployment test PASSED - cleaning up"
                full_cleanup
                exit 0
            else
                echo "❌ Deployment test FAILED - cleaning up"
                full_cleanup
                exit 1
            fi
            ;;
        *)
            echo "❌ Unknown CI command: $CI_COMMAND"
            echo "Available commands: full_setup, full_cleanup, test_deployment"
            exit 1
            ;;
    esac
fi

while true; do
    show_header
    show_menu
    read choice
    
    execute_command "$choice"
    
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
done
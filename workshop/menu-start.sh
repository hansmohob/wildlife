#!/bin/bash

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Execution tracking
declare -A EXECUTION_COUNT=()

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
# Sections: SETUP, CLEANUP, QUICK, ADVANCED
# The menu will auto-number and auto-discover these functions

declare -a MENU_ITEMS=(
    # SETUP COMMANDS
    "create_ecr_repos|Create ECR Repositories|SETUP"
    "build_images|Build Container Images|SETUP"
    "push_images|Push Images to ECR|SETUP"
    "setup_vpc_endpoints|Setup VPC Endpoints|SETUP"
    "deploy_ecs_cluster|Deploy ECS Cluster|SETUP"
    "register_task_definitions|Register Task Definitions|SETUP"
    "create_load_balancer|Create Load Balancer|SETUP"
    "create_ecs_services|Create ECS Services|SETUP"
    "fix_image_upload|Fix Image Upload|SETUP"
    "fix_gps_data|Fix GPS Data|SETUP"
    "create_efs_storage|Create EFS Storage|SETUP"
    
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

    # QUICK ACTIONS
    "full_setup|Full Setup (All Setup Commands)|QUICK"
    "check_status|Check Deployment Status|QUICK"
    "show_app_url|Show Application URL|QUICK"
    "full_cleanup|Full Cleanup (All Cleanup Commands)|QUICK"

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
                "SETUP") echo -e "${CYAN}SETUP COMMANDS:${NC}" ;;
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
    aws ecr create-repository --repository-name wildlife/alerts
    aws ecr create-repository --repository-name wildlife/datadb
    aws ecr create-repository --repository-name wildlife/dataapi
    aws ecr create-repository --repository-name wildlife/frontend 
    aws ecr create-repository --repository-name wildlife/media
    echo -e "${GREEN}✅ ECR Repositories created${NC}"
}

build_images() {
    echo -e "${GREEN}Building Container Images...${NC}"
    cd /home/ec2-user/workspace/my-workspace/container-app && \
        docker build -t wildlife/alerts ./alerts && \
        docker build -t wildlife/datadb ./datadb && \
        docker build -t wildlife/dataapi ./dataapi && \
        docker build -t wildlife/frontend ./frontend && \
        cp ../terraform/ignoreme.txt ./media/dockerfile && \
        docker build -t wildlife/media ./media && \
        docker image ls | grep wildlife
    echo -e "${GREEN}✅ Container images built${NC}"
}

push_images() {
    echo -e "${GREEN}Pushing Images to ECR...${NC}"
    aws ecr get-login-password --region REPLACE_AWS_REGION | docker login --username AWS --password-stdin REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com
    docker tag wildlife/alerts REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/alerts:latest
    docker tag wildlife/datadb REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/datadb:latest
    docker tag wildlife/dataapi REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/dataapi:latest
    docker tag wildlife/frontend REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/frontend:latest
    docker tag wildlife/media REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/media:latest
    stdbuf -oL docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/alerts:latest
    stdbuf -oL docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/datadb:latest
    stdbuf -oL docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/dataapi:latest
    stdbuf -oL docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/frontend:latest
    stdbuf -oL docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/media:latest
    echo -e "${GREEN}Images pushed to ECR${NC}"
}

setup_vpc_endpoints() {
    echo -e "${GREEN}Setting up VPC Endpoints...${NC}"
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
    USERDATA=$(base64 -w 0 /home/ec2-user/workspace/my-workspace/workshop/ec2_user_data.sh)
    ECS_AMI_ID=$(aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended/image_id --query "Parameters[0].Value" --output text)

    echo "Creating launch template..."
    aws ec2 create-launch-template \
        --launch-template-name REPLACE_PREFIX_CODE-launchtemplate-ecs \
        --version-description 1 \
        --launch-template-data "{
            \"ImageId\": \"$ECS_AMI_ID\",
            \"InstanceType\": \"t4g.medium\",
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

    echo "Enabling container insights..."
    aws ecs put-account-setting --name containerInsights --value enhanced

    echo "Creating ECS cluster..."
    aws ecs create-cluster \
        --cluster-name REPLACE_PREFIX_CODE-ecs \
        --service-connect-defaults namespace=wildlife \
        --settings name=containerInsights,value=enhanced \
        --no-cli-pager

    echo "Waiting for cluster to be active..."
    until aws ecs describe-clusters --clusters REPLACE_PREFIX_CODE-ecs --query 'clusters[0].status' --output text | grep -q ACTIVE; do sleep 5; done
    sleep 5

    echo "Creating capacity provider..."
    aws ecs create-capacity-provider \
        --name REPLACE_PREFIX_CODE-capacity-ec2 \
        --auto-scaling-group-provider autoScalingGroupArn=$ASG_ARN,managedScaling='{status=ENABLED,targetCapacity=80}'

    echo "Configuring cluster capacity providers..."
    aws ecs put-cluster-capacity-providers \
        --cluster REPLACE_PREFIX_CODE-ecs \
        --capacity-providers FARGATE FARGATE_SPOT REPLACE_PREFIX_CODE-capacity-ec2 \
        --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
        --no-cli-pager
    echo -e "${GREEN}✅ ECS Cluster deployed${NC}"
}

register_task_definitions() {
    echo -e "${GREEN}Registering Task Definitions...${NC}"
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
    echo "Creating target group..."
    TG_ARN=$(aws elbv2 create-target-group \
        --name REPLACE_PREFIX_CODE-targetgroup-ecs \
        --protocol HTTP \
        --port 5000 \
        --vpc-id REPLACE_VPC_ID \
        --target-type ip \
        --health-check-path /wildlife/health \
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
    echo -e "${GREEN}✅ Load balancer created${NC}"
}

create_ecs_services() {
    echo -e "${GREEN}Creating ECS Services...${NC}"
    TG_ARN=$(aws elbv2 describe-target-groups --names REPLACE_PREFIX_CODE-targetgroup-ecs --query 'TargetGroups[0].TargetGroupArn' --output text)
    
    echo "Creating datadb service..."
    aws ecs create-service \
        --cluster REPLACE_PREFIX_CODE-ecs \
        --service-name REPLACE_PREFIX_CODE-datadb-service \
        --task-definition REPLACE_PREFIX_CODE-datadb-task \
        --desired-count 2 \
        --capacity-provider-strategy capacityProvider=REPLACE_PREFIX_CODE-capacity-ec2,weight=1 \
        --network-configuration "awsvpcConfiguration={subnets=[REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2],securityGroups=[REPLACE_SECURITY_GROUP_APP],assignPublicIp=DISABLED}" \
        --service-connect-configuration "enabled=true,namespace=wildlife,services=[{portName=data-tcp,discoveryName=REPLACE_PREFIX_CODE-datadb,clientAliases=[{port=27017}]}],logConfiguration={logDriver=awslogs,options={awslogs-group=/aws/ecs/service-connect/REPLACE_PREFIX_CODE-app,awslogs-region=REPLACE_AWS_REGION,awslogs-stream-prefix=wildlife}}" \
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
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2],securityGroups=[REPLACE_SECURITY_GROUP_APP],assignPublicIp=DISABLED}" \
        --service-connect-configuration "enabled=true,namespace=wildlife,services=[{portName=data-http,discoveryName=REPLACE_PREFIX_CODE-dataapi,clientAliases=[{port=5000}]}],logConfiguration={logDriver=awslogs,options={awslogs-group=/aws/ecs/service-connect/REPLACE_PREFIX_CODE-app,awslogs-region=REPLACE_AWS_REGION,awslogs-stream-prefix=wildlife}}" \
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
        --service-connect-configuration "enabled=true,namespace=wildlife,services=[{portName=alerts-http,discoveryName=REPLACE_PREFIX_CODE-alerts,clientAliases=[{port=5000}]}],logConfiguration={logDriver=awslogs,options={awslogs-group=/aws/ecs/service-connect/REPLACE_PREFIX_CODE-app,awslogs-region=REPLACE_AWS_REGION,awslogs-stream-prefix=wildlife}}" \
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
        --service-connect-configuration "enabled=true,namespace=wildlife,services=[{portName=media-http,discoveryName=REPLACE_PREFIX_CODE-media,clientAliases=[{port=5000}]}],logConfiguration={logDriver=awslogs,options={awslogs-group=/aws/ecs/service-connect/REPLACE_PREFIX_CODE-app,awslogs-region=REPLACE_AWS_REGION,awslogs-stream-prefix=wildlife}}" \
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
        --service-connect-configuration "enabled=true,namespace=wildlife,services=[{portName=frontend-http,discoveryName=REPLACE_PREFIX_CODE-frontend,clientAliases=[{port=5000}]}],logConfiguration={logDriver=awslogs,options={awslogs-group=/aws/ecs/service-connect/REPLACE_PREFIX_CODE-app,awslogs-region=REPLACE_AWS_REGION,awslogs-stream-prefix=wildlife}}" \
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
    echo -e "${GREEN}🎉 Congratulations! Your Wildlife application is up! Connect at: http://$(aws elbv2 describe-load-balancers --names REPLACE_PREFIX_CODE-alb-ecs --query 'LoadBalancers[0].DNSName' --output text)/wildlife${NC}"
}

fix_image_upload() {
    echo -e "${GREEN}Fixing Image Upload...${NC}"
    aws iam attach-role-policy \
        --role-name REPLACE_PREFIX_CODE-iamrole-ecstask-standard \
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
    ALB_DNS=$(aws elbv2 describe-load-balancers --names REPLACE_PREFIX_CODE-alb-ecs --query 'LoadBalancers[0].DNSName' --output text)
    aws lambda update-function-configuration --function-name REPLACE_PREFIX_CODE-lambda-gps --environment "Variables={API_ENDPOINT=http://$ALB_DNS/wildlife/api/gps}" --no-cli-pager
    echo -e "${GREEN}✅ GPS Data Fixed${NC}"
}

create_efs_storage() {
    echo -e "${GREEN}Creating EFS Storage...${NC}"
    
    aws iam attach-role-policy \
        --role-name REPLACE_PREFIX_CODE-iamrole-ecstask-standard \
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
    aws efs wait file-system-available --file-system-id $EFS_ID
    
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
    until [ "$(aws efs describe-mount-targets --file-system-id $EFS_ID --query 'length(MountTargets[?LifeCycleState==`available`])' --output text)" = "2" ]; do sleep 5; done
    
    ACCESS_POINT_ID=$(aws efs create-access-point \
        --file-system-id $EFS_ID \
        --posix-user Uid=999,Gid=999 \
        --root-directory Path=/mongodb,CreationInfo='{OwnerUid=999,OwnerGid=999,Permissions=755}' \
        --tags Key=Name,Value=REPLACE_PREFIX_CODE-mongodb-access-point \
        --query 'AccessPointId' \
        --output text)
    
    sed -i "s/REPLACE_WITH_EFS_ID/$EFS_ID/g" /home/ec2-user/workspace/my-workspace/container-app/datadb/task_definition_datadb_v2.json
    
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
}

deploy_adot() {
    echo -e "${GREEN}Deploying AWS Distro for OpenTelemetry (ADOT)...${NC}"
    echo "This will update task definitions to v2 with ADOT sidecar containers..."
    
    echo "Updating alerts task definition..."
    aws ecs register-task-definition \
        --cli-input-json file://$HOME/workspace/my-workspace/container-app/alerts/task_definition_alerts_v2.json \
        --no-cli-pager
    aws ecs update-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-alerts-service --task-definition REPLACE_PREFIX_CODE-alerts-task --force-new-deployment --no-cli-pager

    echo "Updating datadb task definition..."
    aws ecs register-task-definition \
        --cli-input-json file://$HOME/workspace/my-workspace/container-app/datadb/task_definition_datadb_v3.json \
        --no-cli-pager
    aws ecs update-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-datadb-service --task-definition REPLACE_PREFIX_CODE-datadb-task --force-new-deployment --no-cli-pager

    echo "Updating dataapi task definition..."
    aws ecs register-task-definition \
        --cli-input-json file://$HOME/workspace/my-workspace/container-app/dataapi/task_definition_dataapi_v3.json \
        --no-cli-pager
    aws ecs update-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-dataapi-service --task-definition REPLACE_PREFIX_CODE-dataapi-task --force-new-deployment --no-cli-pager

    echo "Updating frontend task definition..."
    aws ecs register-task-definition \
        --cli-input-json file://$HOME/workspace/my-workspace/container-app/frontend/task_definition_frontend_v2.json \
        --no-cli-pager
    aws ecs update-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-frontend-service --task-definition REPLACE_PREFIX_CODE-frontend-task --force-new-deployment --no-cli-pager

    echo "Updating media task definition..."
    aws ecs register-task-definition \
        --cli-input-json file://$HOME/workspace/my-workspace/container-app/media/task_definition_media_v2.json \
        --no-cli-pager
    aws ecs update-service --cluster REPLACE_PREFIX_CODE-ecs --service REPLACE_PREFIX_CODE-media-service --task-definition REPLACE_PREFIX_CODE-media-task --force-new-deployment --no-cli-pager

    echo -e "${GREEN}✅ ADOT deployment completed${NC}"
}

check_status() {
    echo -e "${GREEN}Checking Deployment Status...${NC}"
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
    ALB_DNS=$(aws elbv2 describe-load-balancers --names REPLACE_PREFIX_CODE-alb-ecs --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null)
    if [ "$ALB_DNS" != "None" ] && [ "$ALB_DNS" != "" ]; then
        echo ""
        echo -e "${CYAN}🌐 Application URL:${NC}"
        echo "   http://$ALB_DNS/wildlife"
        echo ""
        echo -e "${CYAN}📊 Health Check:${NC}"
        echo "   http://$ALB_DNS/wildlife/health"
    else
        echo -e "${YELLOW}Load balancer not found or not ready yet${NC}"
    fi
}

full_setup() {
    echo -e "${GREEN}Running Full Setup...${NC}"
    echo "This will run commands 1-9 in sequence"
    echo -n "Continue? (y/n): "
    read confirm
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
        configure_iam && \
        create_efs_storage
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
    echo -e "${GREEN}✅ Load Balancer deleted${NC}"
}

cleanup_cluster() {
    echo -e "${RED}Deleting ECS Cluster...${NC}"
    
    echo "Deregistering container instances..."
    CONTAINER_INSTANCES=$(aws ecs list-container-instances --cluster REPLACE_PREFIX_CODE-ecs --query 'containerInstanceArns[]' --output text 2>/dev/null)
    if [ "$CONTAINER_INSTANCES" != "" ]; then
        for INSTANCE_ARN in $CONTAINER_INSTANCES; do
            aws ecs deregister-container-instance --cluster REPLACE_PREFIX_CODE-ecs --container-instance $INSTANCE_ARN --force --no-cli-pager
        done
        
        echo "Waiting for container instances to deregister..."
        while [ "$(aws ecs list-container-instances --cluster REPLACE_PREFIX_CODE-ecs --query 'length(containerInstanceArns)' --output text 2>/dev/null)" != "0" ]; do
            echo "Container instances still active, waiting..."
            sleep 5
        done
    fi

    echo "Removing capacity providers..."
    aws ecs put-cluster-capacity-providers --cluster REPLACE_PREFIX_CODE-ecs --capacity-providers --default-capacity-provider-strategy --no-cli-pager
    
    echo "Deleting capacity provider..."
    aws ecs delete-capacity-provider --capacity-provider REPLACE_PREFIX_CODE-capacity-ec2 --no-cli-pager
    
    echo "Deleting cluster..."
    aws ecs delete-cluster --cluster REPLACE_PREFIX_CODE-ecs --no-cli-pager
    echo -e "${GREEN}✅ ECS Cluster deleted${NC}"
}

cleanup_asg() {
    echo -e "${RED}Deleting Auto Scaling Group...${NC}"
    echo "Force deleting ASG..."
    aws autoscaling delete-auto-scaling-group --auto-scaling-group-name REPLACE_PREFIX_CODE-asg-ecs --force-delete --no-cli-pager
    
    echo "Waiting for Auto Scaling Group to be deleted..."
    while aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names REPLACE_PREFIX_CODE-asg-ecs --query 'AutoScalingGroups[0].AutoScalingGroupName' --output text 2>/dev/null | grep -q REPLACE_PREFIX_CODE-asg-ecs; do
        echo "ASG still exists, waiting..."
        sleep 5
    done
    
    echo "Deleting launch template..."
    aws ec2 delete-launch-template --launch-template-name REPLACE_PREFIX_CODE-launchtemplate-ecs --no-cli-pager
    echo -e "${GREEN}✅ Auto Scaling Group deleted${NC}"
}

cleanup_task_definitions() {
    echo -e "${RED}Deregistering Task Definitions...${NC}"
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
    VPC_ENDPOINTS=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=REPLACE_VPC_ID" "Name=service-name,Values=com.amazonaws.REPLACE_AWS_REGION.ecr.*" --query 'VpcEndpoints[].VpcEndpointId' --output text 2>/dev/null)
    for ENDPOINT_ID in $VPC_ENDPOINTS; do
        echo "Deleting VPC endpoint $ENDPOINT_ID..."
        aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $ENDPOINT_ID --no-cli-pager
    done
    echo -e "${GREEN}✅ VPC Endpoints deleted${NC}"
}

cleanup_efs() {
    echo -e "${RED}Deleting EFS Storage...${NC}"
    EFS_FILESYSTEMS=$(aws efs describe-file-systems --query 'FileSystems[?Tags[?Key==`Name` && contains(Value, `REPLACE_PREFIX_CODE-mongodb-efs`)]].FileSystemId' --output text 2>/dev/null)
    for EFS_ID in $EFS_FILESYSTEMS; do
        echo "Deleting access points for $EFS_ID..."
        ACCESS_POINTS=$(aws efs describe-access-points --file-system-id $EFS_ID --query 'AccessPoints[].AccessPointId' --output text 2>/dev/null)
        for AP_ID in $ACCESS_POINTS; do
            aws efs delete-access-point --access-point-id $AP_ID --no-cli-pager 2>/dev/null
        done
        
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
    echo -e "${GREEN}✅ EFS Storage deleted${NC}"
}

cleanup_ecr() {
    echo -e "${RED}Deleting ECR Repositories...${NC}"
    for REPO in wildlife/alerts wildlife/datadb wildlife/dataapi wildlife/frontend wildlife/media; do
        echo "Deleting repository $REPO..."
        aws ecr delete-repository --repository-name $REPO --force --no-cli-pager 2>/dev/null
    done
    echo -e "${GREEN}✅ ECR Repositories deleted${NC}"
}

cleanup_docker() {
    echo -e "${RED}Cleaning up Docker Images...${NC}"
    echo "Removing local wildlife images..."
    docker rmi wildlife/alerts wildlife/datadb wildlife/dataapi wildlife/frontend wildlife/media 2>/dev/null
    docker rmi REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/alerts:latest 2>/dev/null
    docker rmi REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/datadb:latest 2>/dev/null
    docker rmi REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/dataapi:latest 2>/dev/null
    docker rmi REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/frontend:latest 2>/dev/null
    docker rmi REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/media:latest 2>/dev/null

    echo "Cleaning up unused Docker resources..."
    docker system prune -f
    echo -e "${GREEN}✅ Docker images cleaned${NC}"
}

full_cleanup() {
    echo -e "${RED}⚠️  This will delete ALL wildlife infrastructure!${NC}"
    echo -n "Type 'DELETE' to confirm: "
    read confirm
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

while true; do
    show_header
    show_menu
    read choice
    
    execute_command "$choice"
    
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
done
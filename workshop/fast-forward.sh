### START: 01 Create Image Registry (ECR) ###
aws ecr create-repository --repository-name wildlife/frontend 
aws ecr create-repository --repository-name wildlife/media
aws ecr create-repository --repository-name wildlife/data
aws ecr create-repository --repository-name wildlife/alerts
### END: 01 Create Image Registry (ECR) ###

### START: 02 Build Container Image (ECR) ###
cd /home/ec2-user/workspace/my-workspace/container-app && \
    docker build -t wildlife/alerts ./alerts && \
    docker build -t wildlife/data ./data && \
    docker build -t wildlife/frontend ./frontend && \
    cp ../terraform/ignoreme.txt ./media/dockerfile && \
    docker build -t wildlife/media ./media && \
    docker image ls | grep wildlife
### END: 02 Build Container Image (ECR) ###

### START: 03 Push Container Image (ECR) ###
aws ecr get-login-password --region REPLACE_AWS_REGION | docker login --username AWS --password-stdin REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com
docker tag wildlife/alerts REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/alerts:latest
docker tag wildlife/data REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/data:latest
docker tag wildlife/frontend REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/frontend:latest
docker tag wildlife/media REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/media:latest
docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/alerts:latest
docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/data:latest
docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/frontend:latest
docker push REPLACE_AWS_ACCOUNT_ID.dkr.ecr.REPLACE_AWS_REGION.amazonaws.com/wildlife/media:latest
### END: 03 Push Container Image (ECR) ###

### START: 04 Setup Networking (VPC) ###
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
### END: 04 Setup Networking (VPC) ###

### START: 05 Deploy Cluster (ECS) ###
USERDATA=$(base64 -w 0 /home/ec2-user/workspace/my-workspace/workshop/ec2_user_data.sh)
ECS_AMI_ID=$(aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended/image_id --query "Parameters[0].Value" --output text)

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

aws autoscaling create-auto-scaling-group \
    --auto-scaling-group-name REPLACE_PREFIX_CODE-asg-ecs \
    --launch-template LaunchTemplateName=REPLACE_PREFIX_CODE-launchtemplate-ecs \
    --min-size 2 \
    --max-size 4 \
    --desired-capacity 2 \
    --vpc-zone-identifier "REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2" \
    --tags ResourceId=REPLACE_PREFIX_CODE-asg-ecs,ResourceType=auto-scaling-group,Key=Name,Value=REPLACE_PREFIX_CODE-ecs-instance,PropagateAtLaunch=true

ASG_ARN=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names REPLACE_PREFIX_CODE-asg-ecs --query 'AutoScalingGroups[0].AutoScalingGroupARN' --output text)

aws ecs put-account-setting --name containerInsights --value enhanced

aws ecs create-cluster \
    --cluster-name REPLACE_PREFIX_CODE-ecs \
    --service-connect-defaults namespace=wildlife \
    --settings name=containerInsights,value=enhanced \
    --no-cli-pager

aws ecs create-capacity-provider \
    --name REPLACE_PREFIX_CODE-capacity-ec2 \
    --auto-scaling-group-provider autoScalingGroupArn=$ASG_ARN,managedScaling='{status=ENABLED,targetCapacity=80}'

aws ecs put-cluster-capacity-providers \
    --cluster REPLACE_PREFIX_CODE-ecs \
    --capacity-providers FARGATE FARGATE_SPOT REPLACE_PREFIX_CODE-capacity-ec2 \
    --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
    --no-cli-pager
### END: 05 Deploy Cluster (ECS) ###

### START: 06 Create Task Definition (ECS) ###
aws ecs register-task-definition \
    --cli-input-json file://$HOME/workspace/my-workspace/container-app/alerts/task_definition_alerts.json \
    --no-cli-pager

aws ecs register-task-definition \
    --cli-input-json file://$HOME/workspace/my-workspace/container-app/media/task_definition_media.json \
    --no-cli-pager

aws ecs register-task-definition \
    --cli-input-json file://$HOME/workspace/my-workspace/container-app/data/task_definition_data.json \
    --no-cli-pager

aws ecs register-task-definition \
    --cli-input-json file://$HOME/workspace/my-workspace/container-app/frontend/task_definition_frontend.json \
    --no-cli-pager
### END: 06 Create Task Definition (ECS) ###

### START: 07 Networking (ALB) ###
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

ALB_ARN=$(aws elbv2 create-load-balancer \
    --name REPLACE_PREFIX_CODE-alb-ecs \
    --subnets REPLACE_PUBLIC_SUBNET_1 REPLACE_PUBLIC_SUBNET_2 \
    --security-groups REPLACE_SECURITY_GROUP_ALB \
    --scheme internet-facing \
    --type application \
    --output text \
    --query 'LoadBalancers[0].LoadBalancerArn')

aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TG_ARN --no-cli-pager
### END: 07 Networking (ALB) ###

### START: 08 Create Services (ECS) ###
aws ecs create-service \
    --cluster REPLACE_PREFIX_CODE-ecs \
    --service-name wildlife-data-service \
    --task-definition wildlife-data-task \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2],securityGroups=[REPLACE_SECURITY_GROUP_APP],assignPublicIp=DISABLED}" \
    --service-connect-configuration "enabled=true,namespace=wildlife,services=[{portName=data-tcp,discoveryName=wildlife-data,clientAliases=[{port=27017}]}]" \
    --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" \
    --no-cli-pager

aws ecs create-service \
    --cluster REPLACE_PREFIX_CODE-ecs \
    --service-name wildlife-frontend-service \
    --task-definition wildlife-frontend-task \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2],securityGroups=[REPLACE_SECURITY_GROUP_APP],assignPublicIp=DISABLED}" \
    --service-connect-configuration "enabled=true,namespace=wildlife,services=[{portName=frontend-http,discoveryName=wildlife-frontend,clientAliases=[{port=5000}]}]" \
    --load-balancers "targetGroupArn=$TG_ARN,containerName=wildlife-frontend,containerPort=5000" \
    --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" \
    --no-cli-pager

aws ecs create-service \
    --cluster REPLACE_PREFIX_CODE-ecs \
    --service-name wildlife-alerts-service \
    --task-definition wildlife-alerts-task \
    --desired-count 2 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2],securityGroups=[REPLACE_SECURITY_GROUP_APP],assignPublicIp=DISABLED}" \
    --service-connect-configuration "enabled=true,namespace=wildlife,services=[{portName=alerts-http,discoveryName=wildlife-alerts,clientAliases=[{port=5000}]}]" \
    --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" \
    --no-cli-pager

aws ecs create-service \
    --cluster REPLACE_PREFIX_CODE-ecs \
    --service-name wildlife-media-service \
    --task-definition wildlife-media-task \
    --desired-count 2 \
    --capacity-provider-strategy capacityProvider=REPLACE_PREFIX_CODE-capacity-ec2,weight=1 \
    --network-configuration "awsvpcConfiguration={subnets=[REPLACE_PRIVATE_SUBNET_1,REPLACE_PRIVATE_SUBNET_2],securityGroups=[REPLACE_SECURITY_GROUP_APP],assignPublicIp=DISABLED}" \
    --service-connect-configuration "enabled=true,namespace=wildlife,services=[{portName=media-http,discoveryName=wildlife-media,clientAliases=[{port=5000}]}]" \
    --placement-constraints "type=distinctInstance" \
    --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100" \
    --no-cli-pager
### END: 08 Create Services (ECS) ###

### START: 09 Deploy AWS Distrubution for Open Telemetry (ADOT) ###
aws ecs register-task-definition \
    --cli-input-json file://$HOME/workspace/my-workspace/container-app/alerts/task_definition_alerts_OTEL.json \
    --no-cli-pager

aws ecs update-service --cluster wildlife-ecs --service wildlife-alerts-service --task-definition wildlife-alerts-task --force-new-deployment --no-cli-pager

aws ecs register-task-definition \
    --cli-input-json file://$HOME/workspace/my-workspace/container-app/media/task_definition_media_OTEL.json \
    --no-cli-pager

aws ecs update-service --cluster wildlife-ecs --service wildlife-media-service --task-definition wildlife-media-task --force-new-deployment --no-cli-pager

aws ecs register-task-definition \
    --cli-input-json file://$HOME/workspace/my-workspace/container-app/data/task_definition_data_OTEL.json \
    --no-cli-pager

aws ecs update-service --cluster wildlife-ecs --service wildlife-data-service --task-definition wildlife-data-task --force-new-deployment --no-cli-pager

aws ecs register-task-definition \
    --cli-input-json file://$HOME/workspace/my-workspace/container-app/frontend/task_definition_frontend_OTEL.json \
    --no-cli-pager

aws ecs update-service --cluster wildlife-ecs --service wildlife-frontend-service --task-definition wildlife-frontend-task --force-new-deployment --no-cli-pager
### END: 09 Deploy AWS Distrubution for Open Telemetry (ADOT)###

### 10 Testing ###
# Reconfigure Lambda function to generate data to ECS alert service
ALB_DNS=$(aws elbv2 describe-load-balancers --names REPLACE_PREFIX_CODE-alb-ecs --query 'LoadBalancers[0].DNSName' --output text)
aws lambda update-function-configuration --function-name REPLACE_PREFIX_CODE-lambda-gps --environment "Variables={API_ENDPOINT=http://$ALB_DNS/wildlife/api/gps}" --no-cli-pager
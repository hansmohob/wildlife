#!/bin/bash
# Main setup script for developer environment and optional project application
# This script can be run multiple times on the same instance

# Set up logging to ensure errors are captured on every run
SETUP_LOG="/var/log/devbox-setup.log"
exec > >(tee -a $SETUP_LOG) 2>&1

echo "INFO: Starting setup at $(date)"

# Source the environment variables
if [ -f /etc/devbox-env.sh ]; then
    source /etc/devbox-env.sh
    echo "INFO: Loaded environment variables from /etc/devbox-env.sh"
else
    echo "ERROR: Environment file /etc/devbox-env.sh not found"
    exit 1
fi

# Status file for tracking installation progress
STATUS_FILE="/var/lib/cloud/instance/setup-status.log"

# Function to detect architecture for downloads
detect_architecture() {
  if [ "${INSTANCE_ARCHITECTURE}" = "arm64" ]; then
    echo "aarch64"
  else
    echo "x86_64"
  fi
}

# Function to check if a step has been completed successfully
step_completed() {
    grep -q "^$1: \[OK\]$" $STATUS_FILE
}

# Function to mark a step as completed
mark_step_completed() {
    echo "$1: [OK]" >> $STATUS_FILE
    echo "INFO: Step '$1' completed successfully"
}

# Function to mark a step as failed
mark_step_failed() {
    echo "$1: [FAILED]" >> $STATUS_FILE
    echo "ERROR: Step '$1' failed: $2"
}

# Function to install a component with error handling
install_component() {
    local component_name="$1"
    local install_command="$2"
    local error_message="$3"
    
    if ! step_completed "$component_name"; then
        echo "INFO: Installing $component_name..."
        if eval "$install_command"; then
            mark_step_completed "$component_name"
            return 0
        else
            mark_step_failed "$component_name" "$error_message"
            return 1
        fi
    else
        echo "INFO: $component_name already installed, skipping"
        return 0
    fi
}
#############################
# CORE DEVELOPER ENVIRONMENT
#############################

# Update system packages
install_component "system_updated" \
"dnf update -y -q" \
"Failed to update system packages"

# Install CloudWatch agent
install_component "cloudwatch_installed" \
"dnf install amazon-cloudwatch-agent -y -q && \
 until aws ssm get-parameter --name /${PREFIX_CODE}/config/AmazonCloudWatch-linux --region ${AWS_REGION} &> /dev/null; do \
     echo 'INFO: SSM parameter is not ready...'; \
     sleep 5; \
 done && \
 aws ssm get-parameter --name /${PREFIX_CODE}/config/AmazonCloudWatch-linux --region ${AWS_REGION} --query 'Parameter.Value' --output text > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json && \
 /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s" \
"Failed to install or configure CloudWatch agent"

# Create AWS profile for developer role
install_component "aws_profile_created" \
"su - ec2-user -c 'mkdir -p ~/.aws' && \
 su - ec2-user -c 'cat > ~/.aws/config << EOF
[profile developer]
role_arn = arn:aws:iam::${AWS_ACCOUNT_ID}:role/${PREFIX_CODE}-iamrole-developer
credential_source = Ec2InstanceMetadata
region = ${AWS_REGION}
EOF'" \
"Failed to create AWS profile"

# Install code-server
install_component "code_server_installed" \
"dnf install https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-${INSTANCE_ARCHITECTURE}.rpm -y && \
 mkdir -p /home/ec2-user/.config/code-server && \
 mkdir -p /home/ec2-user/workspace && \
 chown -R ec2-user:ec2-user /home/ec2-user/workspace && \
 echo 'Retrieving password from Secrets Manager...' && \
 PASSWORD=\$(aws secretsmanager get-secret-value --secret-id ${SECRET_CODE_SERVER} --region ${AWS_REGION} --query SecretString --output text | jq -r .password) && \
 if [ -z \"\$PASSWORD\" ]; then echo 'Error: Failed to retrieve password'; exit 1; fi && \
 cat > /home/ec2-user/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8080
auth: password
password: \"$PASSWORD\"
cert: false
EOF
 && chmod 600 /home/ec2-user/.config/code-server/config.yaml && \
 chown -R ec2-user:ec2-user /home/ec2-user/.config && \
 cat > /etc/systemd/system/code-server.service << EOF
[Unit]
Description=code-server
After=network.target

[Service]
Type=simple
User=ec2-user
Environment=HOME=/home/ec2-user
WorkingDirectory=/home/ec2-user/workspace
ExecStart=/usr/bin/code-server --config /home/ec2-user/.config/code-server/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
 && mkdir -p /home/ec2-user/.local/share/code-server/User/ && \
 cat >> /home/ec2-user/.local/share/code-server/User/settings.json << EOF
{
  \"git.enabled\": true,
  \"git.path\": \"/usr/bin/git\",
  \"git.autofetch\": true,
  \"window.menuBarVisibility\": \"classic\",
  \"workbench.startupEditor\": \"none\",
  \"workspace.openFilesInNewWindow\": \"off\",
  \"workbench.colorTheme\": \"Default Dark+\"
}
EOF
 && chown -R ec2-user:ec2-user /home/ec2-user/.local" \
"Failed to install or configure code-server"

# Install Terraform
install_component "terraform_installed" \
"dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo && \
 dnf install -y terraform" \
"Failed to install Terraform"

# Install .NET SDK (if enabled)
if [ "${INSTALL_DOTNET}" = "true" ]; then
    install_component "dotnet_installed" \
    "dnf install -y dotnet-sdk-${DOTNET_VERSION} && \
     echo 'export PATH=\$PATH:/usr/bin/dotnet' >> /home/ec2-user/.bashrc && \
     su - ec2-user -c 'dotnet --version'" \
    "Failed to install .NET Framework"
fi

# Install Docker
install_component "docker_installed" \
"dnf install -y docker && \
 systemctl start docker && \
 systemctl enable docker && \
 usermod -aG docker ec2-user" \
"Failed to install or configure Docker"

# Install VS Code extensions
install_component "extensions_installed" \
"su - ec2-user -c 'code-server --install-extension amazonwebservices.amazon-q-vscode --force' && \
 su - ec2-user -c 'code-server --install-extension amazonwebservices.aws-toolkit-vscode --force' && \
 su - ec2-user -c 'code-server --install-extension hashicorp.terraform --force' && \
 su - ec2-user -c 'code-server --install-extension ms-azuretools.vscode-docker --force'" \
"Failed to install one or more extensions"

# Start code-server service
if ! systemctl is-active --quiet code-server; then
    echo "INFO: Starting code-server service..."
    if systemctl enable code-server && systemctl start code-server; then
        echo "INFO: code-server service started successfully"
    else
        echo "ERROR: Failed to start code-server service"
    fi
else
    echo "INFO: code-server service already running"
fi

# Install git-remote-s3
install_component "git_remote_s3_installed" \
"dnf install git -y -q && \
 dnf install -y python3 python3-pip && \
 pip3 install boto3==${BOTO3_VERSION} && \
 pip3 install git-remote-s3==${GIT_REMOTE_S3_VERSION} && \
 su - ec2-user -c \"git config --global user.name 'EC2 User'\" && \
 su - ec2-user -c \"git config --global user.email 'ec2-user@example.com'\" && \
 su - ec2-user -c \"git config --global init.defaultBranch main\"" \
"Failed to install or configure git-remote-s3"

# Initialize workspace from GitHub or S3
if ! step_completed "workspace_initialized"; then
    # Initialize from either S3 or GitHub
    if [ -n "${S3_ASSET_BUCKET}" ]; then
        echo "INFO: Initializing from S3 assets..."
        if su - ec2-user -c "mkdir -p /home/ec2-user/workspace/my-workspace && \
                          cd /home/ec2-user/workspace/my-workspace && \
                          aws s3 cp --recursive s3://${S3_ASSET_BUCKET}/${S3_ASSET_PREFIX} ./ && \
                          git init && \
                          git add . && \
                          git commit -m 'Initial commit from S3 assets' && \
                          git remote add origin s3+zip://${S3_BUCKET_GIT}/my-workspace && \
                          git push -u origin main"; then
            mark_step_completed "workspace_initialized"
        else
            mark_step_failed "workspace_initialized" "Failed to initialize workspace from S3"
        fi
    else
        echo "INFO: Cloning from GitHub..."
        if su - ec2-user -c "cd /home/ec2-user/workspace && \
                          git clone ${GITHUB_REPO} my-workspace && \
                          cd my-workspace && \
                          git remote remove origin && \
                          git remote add origin s3+zip://${S3_BUCKET_GIT}/my-workspace && \
                          git push -u origin main"; then
            mark_step_completed "workspace_initialized"
        else
            mark_step_failed "workspace_initialized" "Failed to initialize workspace from GitHub"
        fi
    fi
else
    echo "INFO: Workspace already initialized, skipping"
fi

# Set developer profile as default
if [ "${AUTO_SET_DEVELOPER_PROFILE}" = "true" ] && ! step_completed "developer_profile_set"; then
    echo "INFO: Setting up AWS profile defaults..."
    if su - ec2-user -c "echo 'export AWS_PROFILE=developer' >> ~/.bashrc && \
                      echo 'export AWS_REGION=${AWS_REGION}' >> ~/.bashrc && \
                      echo 'export AWS_ACCOUNTID=${AWS_ACCOUNT_ID}' >> ~/.bashrc"; then
        mark_step_completed "developer_profile_set"
    else
        mark_step_failed "developer_profile_set" "Failed to set AWS profile defaults"
    fi
else
    echo "INFO: Skipping AWS profile defaults..."
fi

# Install Amazon Q CLI prerequisites (final installation requires manual IAM IDC setup)
install_component "q_cli_prerequisites" \
"ARCH=\$(detect_architecture) && \
 su - ec2-user -c \"curl --proto '=https' --tlsv1.2 -sSf https://desktop-release.q.us-east-1.amazonaws.com/latest/q-\${ARCH}-linux.zip -o q.zip\" && \
 su - ec2-user -c \"unzip q.zip\" && \
 pip3 install uv==${UV_VERSION} && \
 uv python install ${UV_PYTHON_VERSION} && \
 pip3 install uvenv==${UVENV_VERSION} && \
 uvenv install --python ${MCP_PYTHON_VERSION} awslabs.terraform-mcp-server && \
 uvenv install --python ${MCP_PYTHON_VERSION} awslabs.ecs-mcp-server && \
 uvenv install --python ${MCP_PYTHON_VERSION} awslabs.eks-mcp-server && \
 uvenv install --python ${MCP_PYTHON_VERSION} awslabs.core-mcp-server && \
 uvenv install --python ${MCP_PYTHON_VERSION} awslabs.aws-documentation-mcp-server && \
 su - ec2-user -c \"mkdir -p ~/.amazonq/logs\" && \
 su - ec2-user -c \"ln -sf /home/ec2-user/workspace/my-workspace/.amazonq/mcp.json ~/.amazonq/mcp.json\" && \
 echo 'NOTE: To complete Q CLI setup, see README for IAM IDC instructions'" \
"Failed to set up Amazon Q CLI prerequisites"

#############################
# PROJECT-SPECIFIC COMPONENTS
#############################

# Install MongoDB
install_component "mongodb_installed" \
"ARCH_DIR=\$(detect_architecture) && \
 cat > /etc/yum.repos.d/mongodb-org-${MONGODB_VERSION}.repo << EOF
[mongodb-org-${MONGODB_VERSION}]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2023/mongodb-org/${MONGODB_VERSION}/\${ARCH_DIR}/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-${MONGODB_VERSION}.asc
EOF
 && dnf install -y mongodb-org && systemctl start mongod && systemctl enable mongod" \
"Failed to install or start MongoDB"

# Install Python packages for project app
install_component "python_packages_installed" \
"pip3 install -r /home/ec2-user/workspace/my-workspace/app-ec2/requirements.txt && \
 chown -R ec2-user:ec2-user /home/ec2-user/workspace/my-workspace" \
"Failed to install Python packages"

# Configure project app service
install_component "project_app_configured" \
"cat > /etc/systemd/system/project-app.service << 'EOF'
[Unit]
Description=Project Monitoring Application
After=network.target mongod.service

[Service]
User=ec2-user
Environment=\"PREFIX_CODE=${PREFIX_CODE}\" \"AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}\" \"BUCKET_NAME=${S3_BUCKET_PROJECT}\" \"AWS_REGION=${AWS_REGION}\"
WorkingDirectory=/home/ec2-user/workspace/my-workspace/app-ec2
ExecStart=/usr/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF
 && systemctl enable project-app && systemctl start project-app" \
"Failed to configure or start project app"

# Replace environment variables in configuration files
install_component "env_vars_replaced" \
"perl -i -pe \"BEGIN{undef $/;} \
    s/REPLACE_AWS_ACCOUNT_ID/${AWS_ACCOUNT_ID}/g; \
    s/REPLACE_AWS_REGION/${AWS_REGION}/g; \
    s/REPLACE_PREFIX_CODE/${PREFIX_CODE}/g; \
    s/REPLACE_VPC_ID/${VPC_ID}/g; \
    s/REPLACE_PRIVATE_SUBNET_1/${PRIVATE_SUBNET_1}/g; \
    s/REPLACE_PRIVATE_SUBNET_2/${PRIVATE_SUBNET_2}/g; \
    s/REPLACE_PUBLIC_SUBNET_1/${PUBLIC_SUBNET_1}/g; \
    s/REPLACE_PUBLIC_SUBNET_2/${PUBLIC_SUBNET_2}/g; \
    s/REPLACE_SECURITY_GROUP_APP/${SECURITY_GROUP_APP}/g; \
    s/REPLACE_SECURITY_GROUP_ALB/${SECURITY_GROUP_ALB}/g; \
    \$(find /home/ec2-user/workspace/my-workspace \
        -name \"task_definition_*.json\" -o \
        -name \"fast-forward.sh\")\" && \
 su - ec2-user -c \"cd /home/ec2-user/workspace/my-workspace && git add . && git commit -m 'Update env' && git push origin main\"" \
"Failed to replace environment variables or commit changes"

# Install k6
install_component "k6_installed" \
"curl -sLO \"https://github.com/grafana/k6/releases/download/v${K6_VERSION}/k6-v${K6_VERSION}-linux-${INSTANCE_ARCHITECTURE}.tar.gz\" && \
 tar -xzf k6-v${K6_VERSION}-linux-${INSTANCE_ARCHITECTURE}.tar.gz -C /tmp && \
 install -o root -g root -m 0755 /tmp/k6-v${K6_VERSION}-linux-${INSTANCE_ARCHITECTURE}/k6 /usr/local/bin/k6" \
"Failed to install k6"

# Print summary of installation
echo "INFO: Setup script completed at $(date)"
echo "INFO: Installation summary:"
echo "----------------------------------------"
cat $STATUS_FILE
echo "----------------------------------------"

# Check if any steps failed
if grep -q "\[FAILED\]" $STATUS_FILE; then
    echo "WARNING: Some installation steps failed. Check the status file for details."
    echo "WARNING: See full logs at $SETUP_LOG"
    exit 1
else
    echo "SUCCESS: All installation steps completed successfully."
    echo "INFO: See full logs at $SETUP_LOG"
    exit 0
fi
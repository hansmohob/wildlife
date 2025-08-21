# Terraform variables file - only the variables actually used by CodeBuild
# CodeBuild passes: -var="PrefixCode=${PrefixCode}" -var="Region=${AWS::Region}"

# Core Infrastructure Parameters (passed by CodeBuild)
PrefixCode = "wildlife"
Region     = "us-east-1"

# Wildlife Application Specific
# This will be populated during workshop setup with actual S3 bucket name
wildlife_s3_bucket_name = "wildlife-bucket-placeholder"
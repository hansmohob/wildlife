# Terraform variables file - only the variables actually used by CodeBuild
# CodeBuild passes: -var="PrefixCode=${PrefixCode}" -var="Region=${AWS::Region}"

# Core Infrastructure Parameters (passed by CodeBuild)
PrefixCode = "wildlife"      # Use same prefix as console section
Region     = "us-west-2"     # Corrected region

# Wildlife Application Specific
# Actual S3 bucket name from CloudFormation stack
wildlife_s3_bucket_name = "aws102-ws-s3bucketwildlife-gzhxd8py4ork"

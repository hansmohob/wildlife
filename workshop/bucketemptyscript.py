#!/usr/bin/env python3

import boto3

# Disable logging for Code Server ALB

client = boto3.client('elbv2')

client.modify_load_balancer_attributes(
LoadBalancerArn='REPLACE_CODE_SERVER_ALB',
Attributes=[
        {
        'Key': 'access_logs.s3.enabled',
        'Value': 'false'
        }
    ]
)

# Disable logging for Code Server CloudFront Distribution

client = boto3.client('cloudfront')

# Get current distribution config
response = client.get_distribution_config(Id='REPLACE_CLOUDFRONT_DISTRIBUTION_ID')
config = response['DistributionConfig']
etag = response['ETag']

# Disable logging
config['Logging']['Enabled'] = False

# Update distribution
client.update_distribution(
    Id='REPLACE_CLOUDFRONT_DISTRIBUTION_ID',
    DistributionConfig=config,
    IfMatch=etag
)

# Empty workshop S3 buckets

BUCKETS = [
    'REPLACE_S3_BUCKET_ARTIFACT',
    'REPLACE_S3_BUCKET_GIT',
    'REPLACE_S3_BUCKET_LOGS',
    'REPLACE_S3_BUCKET_WILDLIFE'
]

s3 = boto3.resource('s3')

for bucket_name in BUCKETS:
    try:
        bucket = s3.Bucket(bucket_name)
        bucket.objects.all().delete()
        bucket.object_versions.delete()
        print(f"Deleted all objects from S3 bucket: {bucket_name}")
    except Exception as e:
        print(f"Error deleting objects from S3 bucket: {bucket_name}: {e}")
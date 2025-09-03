#!/usr/bin/env python3

BUCKETS = [
    'REPLACE_S3_BUCKET_ARTIFACT',
    'REPLACE_S3_BUCKET_GIT',
    'REPLACE_S3_BUCKET_LOGS',
    'REPLACE_S3_BUCKET_WILDLIFE'
]

import boto3

s3 = boto3.resource('s3')

for bucket_name in BUCKETS:
    try:
        bucket = s3.Bucket(bucket_name)
        bucket.objects.all().delete()
        bucket.object_versions.delete()
        print(f"Deleted all objects from S3 bucket: {bucket_name}")
    except Exception as e:
        print(f"Error deleting objects from S3 bucket {bucket_name}: {e}")



           s/REPLACE_S3_BUCKET_WILDLIFE/${S3_BUCKET_WILDLIFE}/g;
    s/REPLACE_S3_BUCKET_LOGS/${S3_BUCKET_LOGS}/g;
    s/REPLACE_S3_BUCKET_GIT/${S3_BUCKET_GIT}/g;
    s/REPLACE_S3_BUCKET_ARTIFACT/${S3_BUCKET_ARTIFACT}/g;
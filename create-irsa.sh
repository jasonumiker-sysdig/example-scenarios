#!/bin/bash

EKS_CLUSTER_NAME=Attendee1Cluster
EKS_AWS_REGION=ap-southeast-2
NAMESPACE=security-playground
SERVICE_ACCOUNT_NAME=irsa
IAM_ROLE_NAME=irsa

EKS_OIDC_ID=$(aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --region ${EKS_AWS_REGION} --query "cluster.identity.oidc.issuer" | awk -F'/' '{print $NF}' | tr -d '"')
#echo $EKS_OIDC_ID
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
#echo $AWS_ACCOUNT_ID

cat > trust.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/oidc.eks.${EKS_AWS_REGION}.amazonaws.com/id/${EKS_OIDC_ID}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.${EKS_AWS_REGION}.amazonaws.com/id/${EKS_OIDC_ID}:sub": "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT_NAME}",
          "oidc.eks.${EKS_AWS_REGION}.amazonaws.com/id/${EKS_OIDC_ID}:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
EOF

aws iam create-role --role-name $IAM_ROLE_NAME --assume-role-policy-document file://trust.json --no-cli-pager
rm trust.json

aws iam attach-role-policy --role-name $IAM_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

cat > serviceaccount.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::$AWS_ACCOUNT_ID:role/$IAM_ROLE_NAME
  labels:
    app.kubernetes.io/name: $SERVICE_ACCOUNT_NAME
  name: $SERVICE_ACCOUNT_NAME
  namespace: $NAMESPACE
EOF

aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $EKS_AWS_REGION
kubectl apply -f serviceaccount.yaml
rm serviceaccount.yaml
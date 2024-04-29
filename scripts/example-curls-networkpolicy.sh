#!/usr/bin/env bash
# Script to demonstrate how to interact with security-playground

NODE_IP=$(kubectl get nodes -o wide | awk 'FNR == 2 {print $6}')
NODE_PORT=30000
HELLO_NAMESPACE=hello

echo "Trying to reach hello-server from security-playground"
echo "---"
curl --connect-timeout 5 -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=curl --connect-timeout 5 http://hello-server.$HELLO_NAMESPACE.svc:8080"
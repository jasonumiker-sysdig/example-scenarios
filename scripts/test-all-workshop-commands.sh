#!/bin/bash
./example-curls.sh
./example-curls-restricted.sh
./example-curls-restricted-nodrift.sh
./example-curls-restricted-nomalware.sh
#kubectl apply -f ./security-playground-irsa.yaml
#sleep 10
#./example-curls-bucket-public.sh
#./sysdig-cli-scanner -a app.au1.sysdig.com logstash:7.16.1
./example-curls-networkpolicy.sh
kubectl apply -f ./generated-network-policy.yml
sleep 10
./example-curls-networkpolicy.sh
kubectl logs deployment/hello-client-blocked -n hello
kubectl logs deployment/hello-client -n hello
kubectl apply -f ./generated-network-policy2.yml
sleep 10
./example-curls.sh

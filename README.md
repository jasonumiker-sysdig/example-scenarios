This is a collection of example scenarios to help test your Sysdig Secure

# General Purpose Zero-Day Exploit

Sysdig provides a general-purpose example exploit called Security Playground https://github.com/sysdiglabs/security-playground that is a Python app which just reads and writes whatever paths you GET/POST against it. You can also ask it to execute any command.

To understand a bit more about how that works visit the git repo link above. To deploy it to your environment do a `kubectl apply -f security-playground.yaml`.

The idea with this is that imagine there is another Apache Struts or Log4j critical vulnerability that there is not yet a known CVE for so your vulnerability scans don't pick it up. This shows that Sysdig can help you catch the anomolous behaviors of that being expoited even as a zero day.

You can see various examples of how this works in the example-curls.sh file. To run that script you need to specify first the IP of a Node then the NodePort - e.g. `./example-curls.sh 1.2.3.4 30001`. You can find these by running: 
* `kubectl get nodes -o wide` - the IP is any INTERNAL-IP
* `kubectl get service security-playground -n security-playground` - the port is the port after 8080: under the PORT(S)

NOTE: This is deployed with a service of type NodePort - if you'd prefer it to be a load balancer then modify that manifest to reconfigure it how you'd prefer. Just be careful as this is a very insecure app (by design) - don't put it on the Internet etc.

## Crypto Mining Example

Sysdig provides a crypto mining example at https://github.com/sysdiglabs/policy-editor-attack that we run as #5 in example-curls.sh.

NOTE: This example will deliberatly fail to actually mine - we are just triggering the rules looking for mining tools like cgminer
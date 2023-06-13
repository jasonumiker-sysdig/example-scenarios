This is a collection of example scenarios to help test your Sysdig Secure

# General Purpose Zero-Day Exploit

Sysdig provides a general-purpose example exploit called Security Playground https://github.com/sysdiglabs/security-playground that is a Python app which just reads and writes whatever paths you GET/POST against it. You can also ask it to execute any command.

To understand a bit more about how that works, visit the git repo link above or have a look at [app.py](https://github.com/jasonumiker-sysdig/example-scenarios/blob/main/README.md). To deploy it to your environment do a `kubectl apply -f security-playground.yaml`. You should also run `kubectl apply -f postgres-sakila.yaml` in order for the database exploit in [example-curls.sh](https://github.com/jasonumiker-sysdig/example-scenarios/blob/main/example-curls.sh) to work.

The idea with this is that imagine there is another Apache Struts or Log4j critical vulnerability that there is not yet a known CVE for so your vulnerability scans don't pick it up. This shows that Sysdig can help you catch the anomolous behaviors of that being expoited even as a zero day.

You can see various examples of how this works in the example-curls.sh file. Note that this tries to get the Node IP from kubectl and assumes the port (30000 for the security-playground and 30001 for the security-playground-restricted).

NOTE: This is deployed with a service of type NodePort - if you'd prefer it to be a load balancer then modify that manifest to reconfigure the Service as well as the bash script addresses how you'd prefer. Just be careful as this is a very insecure app (by design) - don't put it on the Internet etc.

## security-playground vs. security-playground-restricted

The [security-playground.yaml](https://github.com/jasonumiker-sysdig/example-scenarios/blob/main/security-playground.yaml) example has three key security issues:
1. It runs as root
1. It is running with `hostPID: true`
1. It is running in a priviledged security context

When these (mis)configurations are done together, they allow you to escape out of the container isolation boundaries and be root on the host. This allows you not just full control over the host but also over/within the other containers.

We use two tools to break out:
* `nsenter` which allows you to switch namespaces (if allowed by those insecure parameters in the PodSpec to do so)
* `crictl` which is used to control the local container runtime (bypassing Kubernetes) (if allowed to the container socket on the host by these insecure parameters in the podspec and nsenter).

The [security-playground-restricted.yaml](https://github.com/jasonumiker-sysdig/example-scenarios/blob/main/security-playground-restricted.yaml) example fixes all these vulnerabilities in the following ways:
1. We build a container image that runs as a non-root user (this requried changes to the Dockerfile as you'll see in [Dockerfile-unprivileged](https://github.com/jasonumiker-sysdig/example-scenarios/blob/main/Dockerfile-unprivileged) vs [Dockerfile](https://github.com/jasonumiker-sysdig/example-scenarios/blob/main/Dockerfile).
1. The PodSpec not only doesn't have hostPID and a privileged securityContext but it adds in the new Pod Security Admission (PSA) restricted mode for the namespace which ensures that they can't be added to the PodSpec to restore them.
1. The restricted PSA also keeps us from trying to specify/restore root permissons (the original container could only run as Root but this one we could specify in the PodSpec to run it as root and it would still work).

## The examples in example-curls.sh and example-curls-restricted.sh

||security-playground|security-playground-restricted|security-playground + container drift enforcement| security-playground-restricted + container drift enforcement|
|-|-|-|-|-|
|1|allowed|blocked (by not running as root)|allowed|blocked (by not running as root)
|2|allowed|blocked (by not running as root)|blocked|blocked (by not running as root)
|3|allowed|blocked (by not running as root)|blocked|blocked (by not running as root)
|4|allowed|allowed|blocked|blocked (by Container Drift)
|5|allowed|blocked (by not running as root and no hostPID and no privileged securityContect)|allowed|blocked (by not running as root and no hostPID and no privileged securityContect)
|6|allowed|blocked (by not running as root and no hostPID and no privileged securityContect)|allowed|blocked (by not running as root and no hostPID and no privileged securityContect)
|7|allowed|blocked (by not running as root and no hostPID and no privileged securityContect)|allowed|blocked (by not running as root and no hostPID and no privileged securityContect)

Run `cat example-curls.sh` to see what we are about to run. To run these against security-playground-restricted instead run `example-curls-restricted.sh`.

### 1. Reading /etc/shadow

This is attempting to read a sensitive file in the filesystem (/etc/shadow). It will trigger the rule `Read sensitive file untrusted` in the `Sysdig Runtime Notable Events` Managed Policy.

#### security-playground-restricted
This will be blocked by our python app not being run as the root user, and therefore not having access to this path, in sysdig-playground-restricted.

### 2. Writing and executing to a file in /bin

First we attempt to write a file in a sensitive path (/bin)- /bin/hello - with the contents "echo hello-world".

Then we try to `chmod +x` our new file. Then we try to run it.

This triggers our Drift Detection as this executable file was not part of the original image and has been added at runtime - which is bad practice and a good way to detect attackers adding new tools to execute inside your container as part of an attack.

#### security-playground-restricted
These will be blocked by our python app not being run as the root user, and therefore not having access to this path, in sysdig-playground-restricted.

### 3. Install nmap and run a scan

As this container is Debian-based you can install packages using `apt`. This is an anti-pattern to do at runtime (if you want to add or update packages you should rebuild the container image and do a new deployment).

In this case we are going to install the `nmap` command which attackers often use when they get in to work out what network they are on and what else they can get to there.

This triggers the: 
* `Launch Package Mangagement Process in Container` rule in the `Sysdig Runtime Notable Events` Managed Policy
* `Launch Suspicious Network Tool in Container` rule in the `Sysdig Runtime Notable Events` Managed Policy
* `Drift Detection`s from `Container Drift` as there are new executable(s) added at runtime by the `apt install`.

#### security-playground-restricted
This will be blocked by our python app not being run as the root user, and therefore not having access to install packages with apt, in security-playground-restricted.

### 4. Crypto Mining Example
Here we are downloading popular crytpo miner cgminer and running it.

This will fire several Rules including:
* `Mailicious filenames written` and `Malicilous binary detected` from the `Sysdig Runtime Threat Intelligence` Managed Policy
* `Drift Detection` from `Container Drift`
* `Detect outbound connections to common miner pool ports` from the `Sysdig Runtime Threat Intelligence` Managed Policy
* `Cryto Mining Detection` from `Machine Learning`

NOTE: If you want to actually mine (needed to trigger a couple of the rules above) remove the --dry-run from the command in the curl

NOTE: This example currently only works with Intel/AMD (not ARM including Apple M1/M2)

#### security-playground-restricted
This is the only example that still works with sysdig-playground-restricted as you don't need to be root to download and run the crypto miner. It can, however, be blocked by a Sysdig Container Drift Policy set to enforce/prevent the drift.

### 5. Break out of our container and install crictl on the host/Node

As discussed above, given the parameters we have specified (run as root, hostPID, privileged) we are allowed to break out of our container/Linux namespace if we ask. You can do that with the tool `nsenter`. We use this to download and install `crictl`, the tool to manage the container runtime directly, on the Node outside the container. We'll leverage this command behind there in the following examples.

This will fire two Rules:
* `Privileged Shell Spawned Inside Container` rule in the `Sysdig Runtime Notable Events` Managed Policy
* `Modify binary dirs` rule in the `Sysdig Runtime Notable Events` Managed Policy

#### security-playground-restricted
This will be blocked by our python app not being run as the root user, and therefore not being root outside the container either in security-playground-restricted. It also would be blocked by not having hostPID and/or the privileged securityContext in the PodSpec.

### 6. Break out of our container and interact with other containers via crictl

The `crictl` command is similar to the Docker CLI and allows you to directly manage the local container runtime (containerd) on the Node - bypassing Kubernetes which normally is how you'd manage it.

We'll start by just running `crictl ps` to get a list of all the containers.

This will fire several the `The docker client is executed in a container` rule in the `Sysdig Runtime Notable Events` Managed Policy

#### security-playground-restricted
This will be blocked by our python app not being run as the root user, and therefore not being root outside the container either in security-playground-restricted. It also would be blocked by not having hostPID and/or the privileged securityContext in the PodSpec.

### 7. Run a command (a psql query) in another container on the same Node (that runs a PostgreSQL DB)

Finally let's exfiltrate some data by running a query within `psql` inside another container on the same host. Even if the database wasn't running within the container (maybe it is an AWS RDS instead) the application Pod needs to have the connection string/secret within it decrypted at runtime in order for *it* to connect. Which means if we can install/run the database client within that other container/Pod then this will still work.

This will fire the  the `The docker client is executed in a container` rule in the `Sysdig Runtime Notable Events` Managed Policy twice (once for the `crictl ps` to find the container ID and another for the `crictl exec` that runs the `psql` command to extract the data).

#### security-playground-restricted
This will be blocked by our python app not being run as the root user, and therefore not being root outside the container either in security-playground-restricted. It also would be blocked by not having hostPID and/or the privileged securityContext in the PodSpec.

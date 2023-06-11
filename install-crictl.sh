#!/bin/bash
nsenter --all --target=1 wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.27.0/crictl-v1.27.0-linux-amd64.tar.gz
nsenter --all --target=1 tar -zxvf crictl-v1.27.0-linux-amd64.tar.gz -C /usr/bin
nsenter --all --target=1 rm -f crictl-v1.27.0-linux-amd64.tar.gz
nsenter --all --target=1 echo "runtime-endpoint: unix:///var/run/containerd/containerd.sock" > /etc/crictl.yaml
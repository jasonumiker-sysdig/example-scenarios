#!/bin/bash
kubectl delete --all pods --namespace=security-playground
kubectl delete --all pods --namespace=security-playground-restricted
kubectl delete --all pods --namespace=security-playground-restricted-nodrift
kubectl delete --all pods --namespace=security-playground-restricted-nomalware
kubectl delete deployment nefarious-workload -n security-playground

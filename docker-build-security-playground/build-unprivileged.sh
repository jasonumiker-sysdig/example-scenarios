#!/bin/bash
docker buildx create --name mybuilder --bootstrap --use 
docker buildx build --file ./Dockerfile-unprivileged --push \
  --platform linux/arm64,linux/amd64 \
  --tag public.ecr.aws/m9h2b5e7/security-playground-unprivileged:070124 \
  .
#docker buildx build --push \
#  --platform linux/arm64,linux/amd64 \
#  --tag public.ecr.aws/m9h2b5e7/security-playground-unprivileged:latest \
#  .
docker buildx rm mybuilder
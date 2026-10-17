#!/usr/bin/env bash
# Build and (re)start the Jenkins controller. UI: http://localhost:8085 (user admin)
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .secrets && chmod 700 .secrets

# Admin password: generated once, kept out of Git
[ -f .secrets/admin-pass ] || openssl rand -base64 18 > .secrets/admin-pass
# Kubeconfig with the cluster's internal address (Jenkins runs on the "kind" network)
# The node's DNS name doesn't resolve on this network, so use its IP (it is in the API cert's SAN)
NODE_IP=$(docker inspect -f '{{(index .NetworkSettings.Networks "kind").IPAddress}}' shoplite-dev-control-plane)
kind get kubeconfig --internal --name shoplite-dev \
  | sed "s#https://shoplite-dev-control-plane:6443#https://$NODE_IP:6443#" > .secrets/kubeconfig

docker build -t shoplite-jenkins:local .
docker rm -f jenkins >/dev/null 2>&1 || true
docker run -d --name jenkins --restart unless-stopped \
  --network kind \
  -p 8085:8080 \
  -e JENKINS_ADMIN_PASSWORD="$(cat .secrets/admin-pass)" \
  -v jenkins_home:/var/jenkins_home \
  -v "$HOME/.docker/run/docker.sock:/var/run/docker.sock" \
  -v "$PWD/..:/repo:ro" \
  -v "$PWD/.secrets/kubeconfig:/run/secrets/kubeconfig:ro" \
  shoplite-jenkins:local
echo "Jenkins starting on http://localhost:8085  user: admin  password: $(cat .secrets/admin-pass)"

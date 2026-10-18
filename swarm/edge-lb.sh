#!/usr/bin/env bash
# L4 forwarder host:8090 -> kind node NodePort 30090 (stands in for MetalLB/HAProxy).
# Rerun after a Docker restart: the kind node's IP can change.
set -euo pipefail
NODE_IP=$(docker inspect -f '{{(index .NetworkSettings.Networks "kind").IPAddress}}' shoplite-dev-control-plane)
docker rm -f k8s-edge-lb >/dev/null 2>&1 || true
docker run -d --name k8s-edge-lb --restart unless-stopped --network kind -p 8090:8090 \
  alpine/socat TCP-LISTEN:8090,fork,reuseaddr "TCP:$NODE_IP:30090" >/dev/null
echo "k8s-edge-lb: host:8090 -> $NODE_IP:30090"

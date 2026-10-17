#!/usr/bin/env bash
# Shift traffic between platforms: ./cutover.sh 90 10   (swarm% k8s%)
set -euo pipefail
cd "$(dirname "$0")"
SWARM=$1 K8S=$2
yq -i "
  (.http.services.shop-cutover.weighted.services[] | select(.name == \"frontend@swarm\") | .weight) = $SWARM |
  (.http.services.shop-cutover.weighted.services[] | select(.name == \"frontend-k8s\") | .weight) = $K8S
" traefik/cutover.yml
echo "weights now: swarm=$SWARM kubernetes=$K8S"

#!/usr/bin/env bash
# Browser access to the monitoring UIs on the kind node (rerun after a Docker restart).
#   Grafana http://localhost:3300   Prometheus http://localhost:9090   Alertmanager http://localhost:9093
set -euo pipefail
IP=$(docker inspect -f '{{(index .NetworkSettings.Networks "kind").IPAddress}}' shoplite-dev-control-plane)
docker rm -f monitoring-ui >/dev/null 2>&1 || true
docker run -d --name monitoring-ui --restart unless-stopped --network kind \
  -p 3300:3300 -p 9090:9090 -p 9093:9093 --entrypoint sh alpine/socat -c "
    socat TCP-LISTEN:3300,fork,reuseaddr TCP:$IP:30300 &
    socat TCP-LISTEN:9090,fork,reuseaddr TCP:$IP:30909 &
    socat TCP-LISTEN:9093,fork,reuseaddr TCP:$IP:30903 &
    wait" >/dev/null
echo "Grafana http://localhost:3300  Prometheus http://localhost:9090  Alertmanager http://localhost:9093"

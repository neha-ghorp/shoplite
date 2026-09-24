#!/usr/bin/env bash
# End-to-end smoke test: frontend -> orders-service -> users-service.
# Usage: scripts/e2e-test.sh [BASE_URL]   (default http://localhost:8080)
set -euo pipefail

BASE_URL="${1:-http://localhost:8080}"
RETRIES="${RETRIES:-30}"

fail() { echo "FAIL: $*" >&2; exit 1; }

echo "Waiting for $BASE_URL/health ..."
for i in $(seq 1 "$RETRIES"); do
  if curl -fsS "$BASE_URL/health" >/dev/null 2>&1; then break; fi
  [ "$i" -eq "$RETRIES" ] && fail "frontend not reachable after $RETRIES attempts"
  sleep 2
done
echo "PASS: frontend /health"

users=$(curl -fsS "$BASE_URL/api/users") || fail "/api/users request failed"
echo "$users" | grep -q '"name":"Alice"' || fail "/api/users missing Alice: $users"
echo "PASS: /api/users (frontend -> users-service)"

orders=$(curl -fsS "$BASE_URL/api/orders") || fail "/api/orders request failed"
# userName is filled in by orders-service calling users-service, so this proves the full chain
echo "$orders" | grep -q '"userName":"Alice"' || fail "/api/orders not enriched with user names: $orders"
echo "PASS: /api/orders (frontend -> orders-service -> users-service)"

curl -fsS "$BASE_URL/" | grep -q '<title>ShopLite</title>' || fail "home page did not render"
echo "PASS: home page"

echo "All e2e checks passed"

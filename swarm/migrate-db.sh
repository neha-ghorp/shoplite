#!/usr/bin/env bash
# Migrate the ShopLite database from Swarm Postgres to the Kubernetes StatefulSet.
# Precondition: chart deployed with postgres.mode=migrating (empty StatefulSet running).
set -euo pipefail
cd "$(dirname "$0")/.."

NS=shop
SWARM_PG=$(docker ps -q --filter name=shoplite_postgres)
swarm_sql() { docker exec -i "$SWARM_PG" psql -U shoplite -d shoplite -v ON_ERROR_STOP=1 "$@"; }
k8s_sql()   { kubectl -n "$NS" exec -i postgres-0 -- psql -U shoplite -d shoplite -v ON_ERROR_STOP=1 "$@"; }
step()      { echo; echo "=== $* ($(date +%H:%M:%S))"; }

step "b) Write freeze: Swarm DB read-only (reads keep working)"
swarm_sql -c "ALTER DATABASE shoplite SET default_transaction_read_only = on;"
# In production also end existing sessions (pg_terminate_backend) so no old session can still write.
if swarm_sql -c "INSERT INTO users VALUES (99, 'should-fail');" 2>/dev/null; then
  echo "write freeze NOT active - aborting"; exit 1
fi
echo "writes are blocked on Swarm DB"

step "c) Copy: pg_dump from Swarm -> restore into Kubernetes"
docker exec "$SWARM_PG" pg_dump -U shoplite -d shoplite --no-owner | k8s_sql -q

step "d) Verify: row count and content checksum must match"
CHECK="SELECT count(*) || ' rows, md5 ' || md5(string_agg(id || ':' || name, ',' ORDER BY id)) FROM users;"
SRC=$(swarm_sql -tAc "$CHECK"); DST=$(k8s_sql -tAc "$CHECK")
echo "swarm: $SRC"; echo "k8s:   $DST"
if [ "$SRC" != "$DST" ]; then
  echo "MISMATCH - rolling back the freeze, apps stay on Swarm DB"
  swarm_sql -c "ALTER DATABASE shoplite SET default_transaction_read_only = off;"
  exit 1
fi

step "e) Switch: Service 'postgres' -> StatefulSet, restart apps (connection pools hold old connections)"
helm upgrade shop helm/shoplite -n "$NS" -f helm/shoplite/values-migration.yaml \
  --set postgres.mode=internal >/dev/null
kubectl -n "$NS" get svc postgres -o jsonpath='postgres Service is now: {.spec.type}{"\n"}'
kubectl -n "$NS" rollout restart deploy/users-service >/dev/null
kubectl -n "$NS" rollout status deploy/users-service --timeout=120s

step "f) Confirm writes work on the new DB  <-- POINT OF NO RETURN"
echo "From here the Swarm DB is stale. Rolling back now needs a reverse copy of new writes."

# ShopLite

Three Node.js services (`frontend` → `orders-service` → `users-service`) deployed to a local
kind cluster with Terraform/Terragrunt, Helm, ArgoCD and GitHub Actions.

```
apps/                      service code + Dockerfiles          (step 1-2)
docker-compose.yml         local run without Kubernetes
helm/shoplite/             one chart for all 3 services        (step 3)
terraform/modules/         kind-cluster, argocd modules        (step 4)
terragrunt/dev/            dev env wiring the modules          (step 5)
argocd/shoplite-dev.yaml   ArgoCD Application -> test branch   (step 6)
.github/workflows/         build -> e2e -> bump tag            (step 7)
scripts/e2e-test.sh        smoke test                          (step 8)
```

## Prerequisites

`docker`, `terraform`, `terragrunt`, `kubectl`, `helm`:

```sh
brew install terragrunt helm kind
```

## 1. Create the cluster and install ArgoCD

```sh
cd terragrunt/dev
terragrunt run --all apply      # older terragrunt: terragrunt run-all apply
kubectl config use-context kind-shoplite-dev
```

ArgoCD UI: http://localhost:8081 (user `admin`), password:

```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

## 2. Build and publish images (GitHub Actions)

GitHub → Actions → **CI/CD** → Run workflow → branch `test`.

The pipeline:
1. **validate**: `helm lint` / `helm template`
2. **build**: pushes `ghcr.io/neha-ghorp/shoplite/<service>:sha-<commit>` (+ `latest`)
3. **e2e**: installs the chart into a throwaway kind cluster on the runner and runs `scripts/e2e-test.sh`
4. **promote**: commits the new tag to `helm/shoplite/values-dev.yaml` on `test`

**One-time, after the first run:** ghcr packages start out private. Make each of the 3 packages public
(GitHub → your profile → Packages → package → Package settings → Change visibility) so your local cluster can pull them.

## 3. Hand the app to ArgoCD

```sh
kubectl apply -f argocd/shoplite-dev.yaml
kubectl -n argocd get application shoplite-dev -w     # wait for Synced / Healthy
```

App: http://localhost:8080. From here on, every pipeline run bumps the tag on `test` and ArgoCD rolls it out.

## 4. End-to-end test against the local cluster

```sh
scripts/e2e-test.sh http://localhost:8080
```

## Without ArgoCD (quick checks)

```sh
docker compose up --build                                   # plain Docker
helm install shoplite helm/shoplite -f helm/shoplite/values-dev.yaml -n shoplite-dev --create-namespace
```

## Tear down

```sh
kubectl delete -f argocd/shoplite-dev.yaml
cd terragrunt/dev && terragrunt run --all destroy
```

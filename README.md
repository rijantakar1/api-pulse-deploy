# API Pulse — Deploy

Docker Compose, Helm, MySQL bootstrap, and Kubernetes manifests for the **API Pulse** demo.

App repos (org `cd-demo`) build/push to **Amazon ECR**; this repo holds Helm/Argo GitOps config.

| Repo | ECR repository |
|------|----------------|
| `api-pulse-web` | `api-pulse-web` |
| `api-pulse-auth-service` | `api-pulse-auth-service` |
| `api-pulse-analytics-service` | `api-pulse-analytics-service` |
| `odin-api` / `odin-ui` | `odin-api` / `odin-ui` |

CI notes: [`docs/CI.md`](docs/CI.md)  
CD (Argo CD / GitOps): [`docs/CD.md`](docs/CD.md)  
ECR setup: [`docs/ECR.md`](docs/ECR.md)  
Odin / Istio: [`docs/ODIN.md`](docs/ODIN.md)

## Layout

```
api-pulse-deploy/
├── argocd/                      # Argo CD Application + AppProject
├── charts/api-pulse/            # Helm chart (ECR app images)
├── charts/odin/                 # Odin TMS chart
├── routing/                     # TenantRouting + generated Istio
├── db/
├── docs/
│   ├── CI.md
│   ├── CD.md
│   ├── ECR.md
│   └── ODIN.md
├── scripts/
│   ├── helm-install.sh
│   ├── refresh-ecr-pull-secret.sh
│   ├── set-ecr-account.sh
│   ├── ensure_ecr_registry.py
│   ├── install-argocd.sh
│   ├── bootstrap-argocd-app.sh
│   ├── bump_values.py
│   ├── port-forward.sh
│   └── build-images-minikube.sh
└── kubernetes/
```

## Argo CD (recommended CD)

See [`docs/CD.md`](docs/CD.md) for install, secrets (`DEPLOY_REPO_TOKEN`, `ARGOCD_REPO_TOKEN`), and E2E checklist.

```bash
./scripts/install-argocd.sh
ARGOCD_REPO_TOKEN=ghp_... ./scripts/bootstrap-argocd-app.sh
kubectl -n argocd port-forward svc/argocd-server 8081:443
```

## Helm (bootstrap without Argo)

```bash
./scripts/helm-install.sh
./scripts/port-forward.sh
```

## Docker Compose

```bash
cp .env.example .env
docker compose pull && docker compose up -d
```

Demo: `admin@acme.demo` / `admin@globex.demo` — password `password123`

## Tenancy model

- Shared deployments in namespace `api-pulse`
- Database-per-tenant + `api_pulse_registry`
- Theme from tenant row after login

## Future

Per-tenant Argo ApplicationSets / tenant-manager mapping is a later phase.

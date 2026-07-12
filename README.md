# API Pulse — Deploy

Docker Compose, Helm, MySQL bootstrap, and Kubernetes manifests for the **API Pulse** demo.

App repos (org `cd-demo`) build/push to Docker Hub; this repo **pulls** those images.

| Repo | Hub image |
|------|-----------|
| `api-pulse-web` | `rajashekhar2390/api-pulse-web` |
| `api-pulse-auth-service` | `rajashekhar2390/api-pulse-auth-service` |
| `api-pulse-analytics-service` | `rajashekhar2390/api-pulse-analytics-service` |

CI notes: [`docs/CI.md`](docs/CI.md)  
CD (Argo CD / GitOps): [`docs/CD.md`](docs/CD.md)

## Layout

```
api-pulse-deploy/
├── argocd/                      # Argo CD Application + AppProject
├── charts/api-pulse/            # Helm chart (Docker Hub images)
├── db/
├── docker-compose.yml           # pulls Hub images
├── docs/
│   ├── CI.md
│   └── CD.md
├── scripts/
│   ├── helm-install.sh          # bootstrap without Argo (optional)
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
